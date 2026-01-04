class_name Player
extends BaseCharacter

#region Signal Definitions
signal coin_collected(first_coin_collected: bool)
signal weapon_swapped(equipped_weapon_type: String)
signal skill_collected(skill_resource_class)
#endregion

#region Node References & Factories
@onready var camera_2d: Camera2D = $Camera2D
@onready var debuglabel: Label = $debuglabel

# Collision & Areas
@onready var default_collision: CollisionShape2D = $CollisionShape2D
@onready var fireball_collision: CollisionShape2D = $FireballShape2D
@onready var burrow_collision: CollisionShape2D = $BurrowShape2D
@onready var hurt_area: HurtArea2D = $Direction/HurtArea2D
@onready var fireball_hit_area: HitArea2D = $Direction/FireballHitArea2D

# Factories & Effects
@onready var blade_factory: Node2DFactory = $Direction/BladeFactory
@onready var skill_factory: Node2DFactory = $Direction/SkillFactory
@onready var jump_fx_factory: Node2DFactory = $Direction/JumpFXFactory
@onready var surface_fx_factory: Node2DFactory = $Direction/SurfaceFXFactory
@onready var slash_fx_factory: Node2DFactory = $Direction/SlashFXFactory
@onready var hurt_particle: CPUParticles2D = $Direction/HurtFXFactory
#endregion

#region Visual System (Sprite Dictionaries)
# We map keys to nodes so we can swap them easily in code
@onready var sprites: Dictionary = {
	"normal": $Direction/AnimatedSprite2D,
	"blade": $Direction/BladeAnimatedSprite2D,
	"wand": $Direction/WandAnimatedSprite2D,
	"wand_sorrow": $Direction/SorrowWandAnimatedSprite2D, # NEW
	"wand_soul": $Direction/SoulWandAnimatedSprite2D,     # NEW
	"fireball": $Direction/FireballSprite2D,
}

@onready var silhouettes: Dictionary = {
	"normal": $Direction/SilhouetteSprite2D,
	"blade": $Direction/SilhouetteBladeAnimatedSprite2D,
	"wand": $Direction/SilhouetteWandAnimatedSprite2D,
}

@onready var fireball_fx: AnimatedSprite2D = $Direction/FireballFXSprite2D
#endregion

#region State Management
enum BuffState { NONE, FIREBALL, BURROW, INVISIBLE }
var current_buff_state: BuffState = BuffState.NONE
var buff_timer: SceneTreeTimer
var buff_end_callbacks: Array[Callable] = []

enum WeaponType { NORMAL, BLADE, WAND }
var current_weapon: WeaponType = WeaponType.NORMAL
# DEFINING THE LEVELS
enum WandLevel { NORMAL, SORROW, SOUL }
var current_wand_level: WandLevel = WandLevel.NORMAL

# Inventory Flags
var has_blade: bool = false
var has_wand: bool = false

# Combat State
var is_invulnerable: bool = false
var is_in_fireball_state: bool = false
var is_in_burrow_state: bool = false
var invulnerable_timer: float = 0.0
var saved_collision_layer: int
var is_able_attack: bool = true

# Targeting
var _targets_in_range: Array[Node2D] = []

# Actor state
var actor_target_x: float = 0.0
var is_actor_moving: bool = false
signal actor_arrived #emit when actor move toward designated target
#endregion

#region Configuration (Exports)
@export_group("Movement")
@export var wall_slide_speed: float = 50.0
@export var max_fall_speed: float = 300.0
@export var dash_speed_mul: float = 5.0
@export var dash_dist: float = 200.0
@export var dash_cd: float = 5.0
@export var push_strength: float = 100.0
@export var coyote_time: float = 0.2  # NEW: Grace period after leaving ground
@export var air_control_multiplier: float = 0.8  # NEW: Air acceleration modifier
@export var jump_buffer_time: float = 0.1  # Can press jump this early

@export_group("Combat")
@export var atk_cd: float = 1.0
@export var blade_throw_speed: float = 300.0
@export var skill_throw_speed: float = 200.0
@export var invulnerable_duration: float = 2.0
@export var fireball_bounciness: float = 1.0

@export_group("Jump Physics")
@export var jump_height: float = 120.0  # How high (in pixels) you jump. (~2 tiles)
@export var jump_time_to_peak: float = 0.5 # Seconds to reach top. Higher = Floatier.
@export var jump_time_to_descent: float = 0.55 # Seconds to fall back down.
#endregion

#region Internal Variables
var speed_multiplier: float = 1.0
var is_dashing: bool = false
var can_dash: bool = true
var can_move: bool = true
var jump_velocity: float
var jump_gravity: float
var fall_gravity: float
var coyote_timer: float = 0.0
var jump_buffer_timer: float = 0.0
#endregion

# ==============================================================================
# LIFECYCLE
# ==============================================================================

func _ready() -> void:
	# Stats Init
	#max_health = 100; health = 100
	#max_mana = 50; mana = 50
	
	# MATH: Calculates exact gravity needed to hit that height in that time
	jump_velocity = ((2.0 * jump_height) / jump_time_to_peak) * -1.0
	jump_gravity = (2.0 * jump_height) / pow(jump_time_to_peak, 2)
	fall_gravity = (2.0 * jump_height) / pow(jump_time_to_descent, 2)
	
	# FIX: Tell BaseCharacter to use our calculated jump velocity
	jump_speed = abs(jump_velocity)  # BaseCharacter expects positive value
	
	super._ready() # Initialize BaseCharacter
	
	# Global Setup
	GameManager.player = self
	add_to_group("player")
	fsm = FSM.new(self, $States, $States/Idle)
	camera_2d.make_current()

	# Connect Signals
	if fireball_hit_area:
		fireball_hit_area.hitted.connect(_on_fireball_hit_enemy)
	
	#Dialogic.timeline_started.connect(func(): can_move = false)
	#Dialogic.timeline_ended.connect(func(): can_move = true)
	
	# Initial Visual Setup
	_hide_all_visuals()
	if has_blade: equip_weapon(WeaponType.BLADE)
	elif has_wand: equip_weapon(WeaponType.WAND)
	else: equip_weapon(WeaponType.NORMAL)

func _physics_process(delta: float) -> void:
	# 1. Update timers/inputs FIRST so the FSM has fresh data
	_update_jump_buffer(delta)
	_update_coyote_time(delta)
	
	super._physics_process(delta) # Animation, FSM, etc.
	
	_handle_invulnerability(delta)
	_handle_rigid_push()

	# Enforce visual state
	if current_buff_state == BuffState.BURROW or current_buff_state == BuffState.INVISIBLE:
		_enforce_invisibility_visuals()
		
	if debuglabel:
		debuglabel.text = str(fsm.current_state.name)


# ==============================================================================
# MOVEMENT & PHYSICS
# ==============================================================================
func set_speed_multiplier(multiplier: float) -> void: 
	speed_multiplier = multiplier
func set_jump_multiplier(multiplier: float) -> void: 
	jump_multiplier = multiplier

func _update_movement(delta: float) -> void:
	if not can_move: 
		velocity = Vector2.ZERO
		return
	
	# Custom gravity system
	var current_gravity = jump_gravity if velocity.y < 0 else fall_gravity
	velocity.y += current_gravity * delta
	
	# Clamp fall speed
	if fsm.current_state == fsm.states.wallcling:
		velocity.y = clamp(velocity.y, -INF, wall_slide_speed)
	else:
		velocity.y = clamp(velocity.y, -INF, max_fall_speed)
	
	# Dashing Override
	if is_dashing: 
		velocity.y = 0

func jump() -> void:
	if current_buff_state == BuffState.BURROW:
		exit_current_buff()
		return
		
	super.jump() # BaseCharacter logic
	jump_fx_factory.create()
		
func _update_jump_buffer(delta: float) -> void:
	if jump_buffer_timer > 0:
		jump_buffer_timer -= delta
	
	if Input.is_action_just_pressed("jump"):
		jump_buffer_timer = jump_buffer_time
		
func _update_coyote_time(delta: float) -> void:
	"""Updates coyote time - grace period for jumping after leaving ground"""
	if is_on_floor():
		coyote_timer = coyote_time
	else:
		coyote_timer = max(0, coyote_timer - delta)

func has_coyote_time() -> bool:
	"""Returns true if player can still jump (on ground OR within coyote time)"""
	return is_on_floor() or coyote_timer > 0

func wall_jump() -> void:
	turn_around()
	# FIX: Use _next_direction because 'direction' hasn't updated yet!
	# _next_direction holds the value we just set in turn_around()
	velocity.x = movement_speed * _next_direction 
	
	# Optional: Add a multiplier if you want the kick to be stronger than walking
	# velocity.x = movement_speed * 1.5 * _next_direction
	jump()

func dash() -> void:
	if not can_dash: return
	velocity.x = movement_speed * dash_speed_mul * direction
	velocity.y = 0.0
	is_dashing = true
	can_dash = false
	
	await get_tree().create_timer(0.2).timeout # Dash Duration
	is_dashing = false
	
	await get_tree().create_timer(dash_cd).timeout
	can_dash = true

func _handle_rigid_push() -> void:
	for i in get_slide_collision_count():
		var c = get_slide_collision(i)
		var body = c.get_collider()
		# Check if it is a RigidBody
		if body is RigidBody2D:
			# FIX: Only push if the object is light enough!
			# If mass is greater than 50kg, treat it as unpushable.
			if body.mass < 50.0:
				body.apply_central_impulse(-c.get_normal() * push_strength)

# ==============================================================================
# COMBAT & WEAPONS
# ==============================================================================

func collect_blade() -> void:
	has_blade = true;
	
	# HOOK HERE: Trigger tutorial on first weapon pickup
	#GameProgressManager.trigger_event("WEAPON")
	
	swap_weapon()

func collect_wand() -> void:
	has_wand = true
	
	# HOOK HERE: Trigger tutorial on first weapon pickup
	#GameProgressManager.trigger_event("WEAPON")
	
	swap_weapon()
	
func can_attack() -> bool:
	if not is_able_attack: return false
	_cancel_invisibility_if_active()
	return current_weapon == WeaponType.BLADE or current_weapon == WeaponType.WAND

func start_atk_cd() -> void:
	is_able_attack = false
	await get_tree().create_timer(atk_cd).timeout
	is_able_attack = true

func throw_blade() -> void:
	if current_weapon != WeaponType.BLADE: return
	
	var blade = blade_factory.create() as RigidBody2D
	if blade:
		var throw_velocity := Vector2(blade_throw_speed * direction, 0.0)
		blade.apply_impulse(throw_velocity)
	
	# Remove Blade Logic
	has_blade = false
	equip_weapon(WeaponType.NORMAL)

func can_throw() -> bool: return has_blade && current_weapon == WeaponType.BLADE

func swap_weapon() -> void:
	# Block swapping during special states
	if current_buff_state == BuffState.FIREBALL: return
	if not has_blade and not has_wand: return

	match current_weapon:
		WeaponType.NORMAL:
			if has_blade: equip_weapon(WeaponType.BLADE)
			elif has_wand: equip_weapon(WeaponType.WAND)
		WeaponType.BLADE:
			if has_wand: equip_weapon(WeaponType.WAND)
			else: equip_weapon(WeaponType.NORMAL)
		WeaponType.WAND:
			if has_blade: equip_weapon(WeaponType.BLADE)
			else: equip_weapon(WeaponType.NORMAL)

func upgrade_wand_to(level: WandLevel) -> void:
	has_wand = true # Ensure they own the weapon type
	current_wand_level = level
	
	# Show notification
	var level_name = "Sorrow" if level == WandLevel.SORROW else "Soul"
	GameProgressManager.trigger_event("WEAPON_UPGRADE_" + level_name.to_upper())
	
	# Refresh visuals if holding the wand
	if current_weapon == WeaponType.WAND:
		equip_weapon(WeaponType.WAND)

func equip_weapon(type: WeaponType) -> void:
	current_weapon = type
	
	match type:
		WeaponType.BLADE: weapon_swapped.emit("blade")
		WeaponType.WAND:
			# EMIT DIFFERENT SIGNALS BASED ON LEVEL
			match current_wand_level:
				WandLevel.NORMAL: weapon_swapped.emit("wand")
				WandLevel.SORROW: weapon_swapped.emit("wand_sorrow")
				WandLevel.SOUL:   weapon_swapped.emit("wand_soul")
		_: weapon_swapped.emit("normal")
		
	_update_visual_state()

# ==============================================================================
# SKILLS & SPELLS
# ==============================================================================

func cast_spell(skill: Skill) -> String:
	# Validation
	if not skill: return "Skill Invalid"
	if mana < skill.mana: return "Not Enough Mana"
	if current_weapon != WeaponType.WAND: return "Require Wand"
	if current_buff_state == BuffState.BURROW: return "Cannot cast in Burrow"

	_cancel_invisibility_if_active()
	
	# Change FSM State to play animation
	cast_skill(skill.animation_name)
	
	# 1. Consume Resources immediately
	mana = max(0, mana - skill.mana)
	mana_changed.emit()
	SkillTreeManager.consume_skill_use(skill.name)

	# 2. Execution (Small delay to sync with animation frame)
	await get_tree().create_timer(0.15).timeout
	
	match skill.type:
		"single_shot":
			_fire_projectile(skill, 1)
		"multi_shot":
			_fire_projectile(skill, 2, 0.3)
		"radial":
			_fire_radial(skill, 18)
		"area":
			_fire_area(skill)
		"buff":
			_apply_buff_skill(skill)
		_:
			return "Unknown Skill Type"
			
	return ""

# --- Skill Helpers ---

func _fire_projectile(skill: Skill, count: int, delay: float = 0.0) -> void:
	var dir := Vector2.RIGHT if direction == 1 else Vector2.LEFT
	
	for i in range(count):
		var proj = _spawn_projectile_node(skill, dir)
		if delay > 0: await get_tree().create_timer(delay).timeout

func _fire_radial(skill: Skill, count: int) -> void:
	for i in range(count):
		var angle = (float(i) / count) * 2.0 * PI
		var dir = Vector2(cos(angle), sin(angle)).normalized()
		_spawn_projectile_node(skill, dir)

func _spawn_projectile_node(skill: Skill, dir: Vector2) -> Area2D:
	# Use specific scene or fallback to factory
	var proj_node: Node
	if skill.projectile_scene:
		proj_node = skill.projectile_scene.instantiate()
	elif skill_factory:
		proj_node = skill_factory.create()
	else:
		return null
		
	var proj = proj_node as Area2D
	if not proj: return null
	
	proj.global_position = skill_factory.global_position
	get_tree().current_scene.add_child(proj)

	if proj.has_method("setup"):
		proj.setup(skill, dir)
	else:
		# Manual Property Injection fallback
		if "speed" in proj: proj.speed = skill.speed
		if "damage" in proj: proj.damage = skill.damage
		if "direction" in proj: proj.direction = dir
		
	return proj

func _fire_area(skill: Skill) -> void:
	var target_pos = global_position
	var target_enemy = null
	
	if skill.ground_targeted:
		target_pos = global_position
	elif has_valid_target_in_range():
		target_enemy = get_closest_target()
		if is_instance_valid(target_enemy):
			target_pos = target_enemy.global_position
	else:
		# If no target, maybe fail or cast at self?
		return

	if not skill.area_scene: return
	var area_node = skill.area_scene.instantiate()
	get_tree().current_scene.add_child(area_node)
	area_node.global_position = target_pos
	
	if area_node.has_method("setup"):
		area_node.setup(skill, position, target_enemy)

func _apply_buff_skill(skill: Skill) -> void:
	var duration = skill.duration * (skill.level + 1.0) / 2.0
	
	if skill is Fireball:
		enter_buff_state(BuffState.FIREBALL, duration)
	elif skill is Burrow:
		enter_buff_state(BuffState.BURROW, duration)
	elif skill is HealOverTime:
		_apply_heal_over_time(skill.heal_per_tick, duration, skill.tick_interval)

func _apply_heal_over_time(amount: float, duration: float, interval: float) -> void:
	var ticks = floor(duration / interval)
	for i in range(ticks):
		if health <= 0: break
		health = min(health + amount, max_health)
		health_changed.emit()
		await get_tree().create_timer(interval).timeout

# ==============================================================================
# BUFF STATE MACHINE
# ==============================================================================

func enter_buff_state(new_state: BuffState, duration: float = 0.0, end_callback: Callable = Callable()) -> void:
	exit_current_buff() # Clean up previous
	
	current_buff_state = new_state
	
	# Timer Setup
	if duration > 0:
		buff_timer = get_tree().create_timer(duration)
		buff_timer.timeout.connect(exit_current_buff)
	
	if end_callback.is_valid():
		buff_end_callbacks.append(end_callback)
		
	# Apply State Logic
	match new_state:
		BuffState.FIREBALL: _set_fireball_state(true)
		BuffState.BURROW: _set_burrow_state(true)
		BuffState.INVISIBLE: _set_invisible_state(true)

func exit_current_buff() -> void:
	# Cleanup Timer
	if buff_timer: 
		buff_timer.disconnect("timeout", exit_current_buff)
		buff_timer = null

	# Run Callbacks
	for cb in buff_end_callbacks: 
		if cb.is_valid(): cb.call()
	buff_end_callbacks.clear()

	# Remove State Logic
	match current_buff_state:
		BuffState.FIREBALL: _set_fireball_state(false)
		BuffState.BURROW: _set_burrow_state(false)
		BuffState.INVISIBLE: _set_invisible_state(false)
	
	current_buff_state = BuffState.NONE
	_update_visual_state()

func _set_fireball_state(active: bool) -> void:
	fireball_collision.set_deferred("disabled", !active)
	hurt_area.set_deferred("monitorable", !active)
	fireball_hit_area.monitoring = active
	set_collision_mask_value(4, active) # Adjust layer as needed
	
	if active:
		is_in_fireball_state = true # Maintain old bool if FSM needs it
		elemental_type = ElementsEnum.Elements.FIRE
		speed_multiplier = 2.0
		change_animation("Fireball")
		fireball_fx.show(); fireball_fx.play()
		_update_visual_state(sprites.fireball) # Force fireball sprite
	else:
		is_in_fireball_state = false
		elemental_type = ElementsEnum.Elements.NONE
		speed_multiplier = 1.0
		fireball_fx.hide(); fireball_fx.stop()

func _set_burrow_state(active: bool) -> void:
	is_in_burrow_state = active
	
	if active:
		AudioManager.play_sound("skill_burrow")
		# --- ENTERING BURROW ---
		default_collision.set_deferred("disabled", true)
		burrow_collision.set_deferred("disabled", false)
		hurt_area.set_deferred("monitorable", false)
		
		speed_multiplier = 1.25
		_update_visual_state(null, true) 
		if is_on_floor():
			surface_fx_factory.create()
	else:
		# --- EXITING BURROW ---
		speed_multiplier = 1.0
		
		# 1. Physics Launch
		surface_fx_factory.create()
		velocity.y = -jump_speed 
		velocity.x = 400.0 * direction
		
		# 2. Visuals
		if animated_sprite: animated_sprite.play("jump")

		# 3. Dynamic Hitbox Restoration
		# We DO NOT enable default_collision yet. 
		# We start the watcher to do it when safe.
		_await_safe_hitbox_expansion()
		
func _await_safe_hitbox_expansion() -> void:
	# 1. Setup the query using your Default Hitbox's shape
	var space_state = get_world_2d().direct_space_state
	var query = PhysicsShapeQueryParameters2D.new()
	query.shape = default_collision.shape
	# We use the player's global transform so the query follows you as you jump
	query.transform = global_transform 
	# Set this to your World/Environment layer (usually Layer 1)
	# Do not include enemies or hitboxes, or you'll never un-burrow next to them.
	query.collision_mask = 1 
	
	# 2. Loop until empty
	while true:
		# Update query position to match player's current position (in case they are moving)
		query.transform = global_transform
		
		# Ask the physics engine for overlaps
		var results = space_state.intersect_shape(query, 1) # Max 1 result needed to fail
		
		if results.is_empty():
			# SUCCESS: No walls inside our shape. Safe to expand.
			default_collision.set_deferred("disabled", false)
			burrow_collision.set_deferred("disabled", true)
			hurt_area.set_deferred("monitorable", true)
			break # Exit the loop
		
		# If we hit something, wait for the next physics frame and try again
		await get_tree().physics_frame

func _set_invisible_state(active: bool) -> void:
	hurt_area.set_deferred("monitorable", !active)
	collision_layer = 0 if active else (1 << 1) # Example layer mask logic
	
	if active:
		_update_visual_state(null, true) # Force silhouette
		
	else:
		# Handled by generic _update_visual_state in exit_current_buff
		pass

func _cancel_invisibility_if_active() -> void:
	if current_buff_state == BuffState.INVISIBLE:
		exit_current_buff()

# ==============================================================================
# VISUAL CONTROLLER
# ==============================================================================

func _hide_all_visuals() -> void:
	for k in sprites: 
		if sprites[k]: sprites[k].hide()
	for k in silhouettes: 
		if silhouettes[k]: silhouettes[k].hide()
	if fireball_fx: fireball_fx.hide()

func _update_visual_state(forced_main: AnimatedSprite2D = null, force_silhouette: bool = false) -> void:
	# 1. Fireball overrides everything
	if current_buff_state == BuffState.FIREBALL:
		_hide_all_visuals()
		sprites.fireball.show()
		fireball_fx.show()
		return

	_hide_all_visuals()

	# 2. Determine Active Sprites based on Weapon
	var active_main: AnimatedSprite2D
	var active_silhouette: AnimatedSprite2D
	
	match current_weapon:
		WeaponType.BLADE:
			active_main = sprites.blade
			active_silhouette = silhouettes.blade
		WeaponType.WAND:
			# SELECT SPRITE BASED ON LEVEL
			match current_wand_level:
				WandLevel.NORMAL:
					active_main = sprites.wand
					active_silhouette = silhouettes.wand
				WandLevel.SORROW:
					active_main = sprites.wand_sorrow
					active_silhouette = silhouettes.wand
				WandLevel.SOUL:
					active_main = sprites.wand_soul
					active_silhouette = silhouettes.wand
		_:
			active_main = sprites.normal
			active_silhouette = silhouettes.normal

	if forced_main: active_main = forced_main

	# 3. Apply Visibility
	# If in burrow/invisible, HIDE main, SHOW silhouette
	if force_silhouette or current_buff_state in [BuffState.BURROW, BuffState.INVISIBLE]:
		if active_silhouette:
			active_silhouette.show()
			active_silhouette.modulate.a = 0.5
			# Update list for BaseCharacter to not mess up
			extra_sprites = [active_silhouette]
	else:
		# Normal state
		if active_main:
			set_animated_sprite(active_main) # Inform BaseCharacter
			active_main.show()
			active_main.modulate.a = 1.0
		if active_silhouette:
			active_silhouette.show()
			active_silhouette.modulate.a = 0.5
			# Update list for BaseCharacter to not mess up
			extra_sprites = [active_silhouette]	
	_update_elemental_palette()

func _enforce_invisibility_visuals() -> void:
	# 1. Force the Main Sprite (Detailed) to HIDE
	# BaseCharacter tries to show this every frame when animating, so we must force it off.
	if animated_sprite:
		animated_sprite.hide()

	# 2. Force the Silhouette (Shadow) to SHOW and be TRANSPARENT
	# The silhouette is stored in 'extra_sprites' by _update_visual_state
	for s in extra_sprites:
		if is_instance_valid(s):
			s.show()
			s.modulate.a = 0.5

func _update_elemental_palette() -> void:
	if not is_instance_valid(animated_sprite): return
	
	# Basic Shader logic placeholder
	var shader_mat = animated_sprite.material as ShaderMaterial
	if shader_mat:
		shader_mat.set_shader_parameter("elemental_type", elemental_type)
		shader_mat.set_shader_parameter("is_fireball_state", current_buff_state == BuffState.FIREBALL)

# ==============================================================================
# TARGETING & DAMAGE
# ==============================================================================

func _on_detection_area_2d_body_entered(body: Node2D):
	if body.is_in_group("enemies") or body is EnemyCharacter:
		if not _targets_in_range.has(body): _targets_in_range.append(body)

func _on_detection_area_2d_body_exited(body: Node2D):
	if _targets_in_range.has(body): _targets_in_range.erase(body)

func has_valid_target_in_range() -> bool:
	_targets_in_range = _targets_in_range.filter(func(t): return is_instance_valid(t))
	return not _targets_in_range.is_empty()

func get_closest_target() -> Node2D:
	if not has_valid_target_in_range(): return null
	var closest: Node2D = null
	var min_dist = INF
	
	for t in _targets_in_range:
		var d = global_position.distance_squared_to(t.global_position)
		if d < min_dist:
			min_dist = d
			closest = t
	return closest

func _on_hurt_area_2d_hurt(_direction: Vector2, _damage: float, _elemental_type: int) -> void:
	var modified_damage = calculate_elemental_damage(_damage, _elemental_type)
	
	# Let FSM handle the animation/knockback
	if fsm.current_state.has_method("take_damage"):
		fsm.current_state.take_damage(_direction, modified_damage)
	
	handle_elemental_damage(_elemental_type)
	if hurt_particle: hurt_particle.emitting = true

func _handle_invulnerability(delta: float) -> void:
	if not is_invulnerable: return
	
	invulnerable_timer -= delta
	
	# Flicker Effect
	var is_visible_frame = fmod(invulnerable_timer, 0.2) > 0.1
	if animated_sprite:
		animated_sprite.modulate.a = 0.5 if is_visible_frame else 1.0

	if invulnerable_timer <= 0:
		is_invulnerable = false
		hurt_area.collision_layer = saved_collision_layer
		if animated_sprite: animated_sprite.modulate.a = 1.0

func set_invulnerable() -> void:
	is_invulnerable = true
	invulnerable_timer = invulnerable_duration
	saved_collision_layer = hurt_area.collision_layer
	hurt_area.collision_layer = 0

# ==============================================================================
# ELEMENTAL LOGIC & FIREBALL BOUNCE
# ==============================================================================

func _on_fireball_hit_enemy(_hurt_area: Area2D) -> void:
	if current_buff_state != BuffState.FIREBALL: return
	var enemy = _hurt_area.get_parent()
	if enemy:
		# Bounce away from enemy
		var dir_away = (global_position - enemy.global_position).normalized()
		var bounce_force = 500.0
		velocity = dir_away * bounce_force

func calculate_elemental_damage(base: float, attacker_elem: int) -> float:
	if attacker_elem == ElementsEnum.Elements.NONE: return base
	
	# Simplified Element Cycle
	# Metal(1) > Wood(2) > Earth(5) > Water(3) > Fire(4) > Metal(1)
	var advantages = {
		ElementsEnum.Elements.METAL: [ElementsEnum.Elements.WOOD],
		ElementsEnum.Elements.WOOD:  [ElementsEnum.Elements.EARTH],
		ElementsEnum.Elements.EARTH: [ElementsEnum.Elements.WATER],
		ElementsEnum.Elements.WATER: [ElementsEnum.Elements.FIRE],
		ElementsEnum.Elements.FIRE:  [ElementsEnum.Elements.METAL]
	}
	
	if advantages.has(attacker_elem) and elemental_type in advantages[attacker_elem]:
		return base * 1.5 # Critical
	if advantages.has(elemental_type) and attacker_elem in advantages[elemental_type]:
		return base * 0.5 # Resist
		
	return base

func handle_elemental_damage(elem: int) -> void:
	# Placeholder for status effects (Burn, Slow, etc)
	pass

# ==============================================================================
# SAVE / LOAD
# ==============================================================================

func save_state() -> Dictionary:
	return {
		"position": [global_position.x, global_position.y],
		"has_blade": has_blade,
		"has_wand": has_wand,
		"wand_level": current_wand_level
	}

func load_state(data: Dictionary) -> void:
	if "position" in data:
		global_position = Vector2(data["position"][0], data["position"][1])
	if "has_blade" in data:
		has_blade = data["has_blade"]
		if has_blade: equip_weapon(WeaponType.BLADE)
	if "has_wand" in data:
		has_wand = data["has_wand"]
		if has_wand: equip_weapon(WeaponType.WAND)
	if "wand_level" in data:
		current_wand_level = data["wand_level"]
	
	# Helper definitions for FSM/Animation use
func cast_skill(anim_name: String) -> void:
	if fsm.current_state != fsm.states.castspell:
		fsm.change_state(fsm.states.castspell)

# ==============================================================================
# SKILL COLLECTION & MANAGEMENT
# ==============================================================================

func add_new_skill(skill: Skill, stack_amount: int = 1) -> void:
	"""
	Adds a new skill to the player's collection
	stack_amount: How many charges/stacks to add (default 1)
	Returns true on success, false on failure
	"""
	if not skill:
		push_error("Player.add_new_skill: Invalid skill resource")
	
	if stack_amount <= 0:
		push_warning("Player.add_new_skill: Invalid stack amount %d" % stack_amount)
	
	# Add to SkillTreeManager
	SkillTreeManager.collect_skill(skill.name, stack_amount)
	skill_collected.emit(skill, stack_amount)

# ==============================================================================
# CUTSCENE LOGIC
# ==============================================================================

func toggle_actor_state() -> void:
	if fsm.current_state == fsm.states.actor:
		fsm.change_state(fsm.states.idle)
	else:
		fsm.change_state(fsm.states.actor)

func move_to_scene_point(point_name: String) -> void:
	# 1. Find the node in the current scene (recursive search)
	var scene = get_tree().current_scene
	var target_node = scene.find_child(point_name, true, false)
	
	if not target_node:
		push_error("Player: Could not find node named '%s' for actor movement." % point_name)
		return

	# 2. Setup Movement State
	actor_target_x = target_node.global_position.x
	print(actor_target_x)
	is_actor_moving = true
	
	fsm.change_state(fsm.states.actor)
	change_animation("run")
	Dialogic.paused = true
	
	# 3. Switch FSM to Actor/Cutscene state to disable standard logic
	# (Assuming 'actor' is the state name in your FSM)
	#if fsm.has_state("actor"):
		#fsm.change_state(fsm.states.actor)

func _handle_actor_physics() -> void:
	# Calculate distance to target
	var dist = actor_target_x - global_position.x
	#print(str(actor_target_x) + " " + str(global_position.x))
	# if arrive then stop and resume dialogic
	if abs(dist) < 5.0:
		velocity.x = 0
		is_actor_moving = false
		change_animation("idle")
		actor_arrived.emit() # Signal Dialogic that we are done
		Dialogic.paused = false
	else: #moving logic
		direction = sign(dist)
		velocity.x = direction * movement_speed

func _apply_gravity_only(delta: float) -> void:
	# Copied strictly gravity logic from _update_movement
	# This ensures the actor falls if the target is on a lower platform
	var current_gravity = jump_gravity if velocity.y < 0 else fall_gravity
	velocity.y += current_gravity * delta
	velocity.y = clamp(velocity.y, -INF, max_fall_speed)
