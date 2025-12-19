class_name Player
extends BaseCharacter

@onready var camera_2d: Camera2D = $Camera2D

#Invulnerable Logic
@export var invulnerable_duration: float = 2
var is_invulnerable: bool = false
var invulnerable_timer: float = 0
const FLICKER_INTERVAL := 0.1
var flicker_timer := 0.0
var saved_collision_layer: int

#Invisible Logic
var _invisible_timer: SceneTreeTimer = null
var _is_invisible: bool = false

# Add this near your other export variables
@export var fireball_bounciness: float = 1.0
@export var minimum_bounce_velocity: float = 300.0

#Attack Logic
@export var atk_cd: float = 1
var is_able_attack: bool = true 
@export var has_blade: bool = false
@export var has_wand: bool = true
var is_in_fireball_state: bool = false
var is_equipped_blade: bool = false   
var is_equipped_wand: bool = false    
signal weapon_swapped(equipped_weapon_type: String)

var blade_hit_area: Area2D
@export var blade_throw_speed: float = 300
@export var skill_throw_speed: float = 200

# Factories & Effects
@onready var blade_factory: Node2DFactory = $Direction/BladeFactory
@onready var jump_fx_factory: Node2DFactory = $Direction/JumpFXFactory
@onready var skill_factory: Node2DFactory = $Direction/SkillFactory
@onready var hurt_particle: CPUParticles2D = $Direction/HurtFXFactory
@onready var slash_fx_factory: Node2DFactory = $Direction/SlashFXFactory

@onready var hurt_area: HurtArea2D = $Direction/HurtArea2D
@onready var fireball_hit_area: HitArea2D = $Direction/FireballHitArea2D
@onready var fireball_collision: CollisionShape2D = $FireballShape2D

@export var push_strength = 100.0

# Sprites
@onready var normal_sprite: AnimatedSprite2D = $Direction/AnimatedSprite2D
@onready var blade_sprite: AnimatedSprite2D = $Direction/BladeAnimatedSprite2D
@onready var wand_sprite: AnimatedSprite2D = $Direction/WandAnimatedSprite2D 
@onready var silhouette_normal_sprite: AnimatedSprite2D = $Direction/SilhouetteSprite2D
@onready var silhouette_blade_sprite: AnimatedSprite2D = $Direction/SilhouetteBladeAnimatedSprite2D
@onready var silhouette_wand_sprite: AnimatedSprite2D = $Direction/SilhouetteWandAnimatedSprite2D
@onready var fireball_sprite: AnimatedSprite2D = $Direction/FireballSprite2D
@onready var fireball_fx: AnimatedSprite2D = $Direction/FireballFXSprite2D

#Movement
var last_dir: float = 0.0
@export var wall_slide_speed: float = 50.0
@export var max_fall_speed: float = 100.0
var can_move: bool = true

#dash
@export var dash_speed_mul: float = 5.0
@export var dash_dist: float = 200.0
@export var dash_cd: float = 5.0
var is_dashing: bool = false
var can_dash: bool = true

#Debug
@onready var debuglabel: Label = $debuglabel

var _targets_in_range: Array[Node2D] = []

signal skill_collected(skill_resource_class)

func _ready() -> void:
	_hide_all_visuals()
	super._ready() # Calls BaseCharacter _ready
	
	fsm = FSM.new(self, $States, $States/Idle)
	GameManager.player = self
	add_to_group("player")
	
	# Initial Visual Setup
	if has_blade:
		collected_blade()
	elif has_wand:
		collected_wand()
	else:
		_set_player_visuals(normal_sprite, silhouette_normal_sprite)
		
	# Connect the HitArea signal to our bounce logic
	if fireball_hit_area:
		fireball_hit_area.hitted.connect(_on_fireball_hit_enemy)
	
	camera_2d.make_current()
	Dialogic.timeline_started.connect(_on_dialog_started)
	Dialogic.timeline_ended.connect(_on_dialog_ended)

func _hide_all_visuals() -> void:
	normal_sprite.hide()
	blade_sprite.hide()
	wand_sprite.hide()
	fireball_sprite.hide()
	silhouette_normal_sprite.hide()
	silhouette_blade_sprite.hide()
	silhouette_wand_sprite.hide()

# ================================================================
# === SKILL & LOGIC ==============================================
# ================================================================

func _on_dialog_started(): can_move = false
func _on_dialog_ended(): can_move = true

func _check_and_use_skill_stack(skill_to_use: Skill):
	var skillbar_root = get_tree().get_first_node_in_group("skill_bar")
	var skill_bar
	if skillbar_root: skill_bar = skillbar_root.get_node("MarginContainer/SkillBar")
	if skill_bar:
		for i in range(skill_bar.slots.size()):
			var slot = skill_bar.slots[i]
			if slot.skill == skill_to_use:
				var stack = SkillStackManager.get_stack(skill_to_use.name)
				var unlocked = SkillStackManager.get_unlocked(skill_to_use.name)
				if unlocked: return
				if stack == 1: SkillStackManager.clear_skill_in_bar(i)
				elif stack > 1:
					SkillStackManager.remove_stack(skill_to_use.name, 1)
					slot.update_stack_ui()
				return 

func add_new_skill(new_skill_class: Script) -> bool:
	skill_collected.emit(new_skill_class)
	return true

func cast_spell(skill: Skill) -> String:
	if not skill: return "Skill invalid"
	if(mana - skill.mana < 0): return "Not Enough Mana"
	if not is_equipped_wand: return "Require Wand"
	_cancel_invisibility_if_active()
		
	await get_tree().create_timer(0.15).timeout
	match skill.type:
		"single_shot":
			_single_shot(skill)
			mana = max(0, mana - skill.mana); mana_changed.emit()
			_check_and_use_skill_stack(skill); return ""
		"multi_shot":
			_multi_shot(skill, 2, 0.3)
			mana = max(0, mana - skill.mana); mana_changed.emit()
			_check_and_use_skill_stack(skill); return ""
		"radial":
			_radial(skill, 18)
			mana = max(0, mana - skill.mana); mana_changed.emit()
			_check_and_use_skill_stack(skill); return ""
		"area": 
			cast_skill(skill.animation_name)
			mana = max(0, mana - skill.mana); mana_changed.emit()

			if skill.ground_targeted:
				# Ground-targeted: cast at player position
				_area_shot(skill, global_position, null)
			elif has_valid_target_in_range():
				var target = get_closest_target()
				if is_instance_valid(target):
					_area_shot(skill, target.global_position, target)
			else:
				return "Enemy Out of Range"

			_check_and_use_skill_stack(skill); return ""
		"buff":
			cast_skill(skill.animation_name)
			_apply_buff(skill)
			mana = max(0, mana - skill.mana); mana_changed.emit()
			_check_and_use_skill_stack(skill); return "" 
		_: return "Unknown Skill Type"
	return ""

# Skill Helpers
func _single_shot(skill: Skill) -> void:
	var dir := Vector2.RIGHT if direction == 1 else Vector2.LEFT
	cast_skill(skill.animation_name)
	_spawn_projectile(skill, dir)

func _multi_shot(skill: Skill, count: int, delay: float) -> void:
	for i in range(count):
		_single_shot(skill); await get_tree().create_timer(delay).timeout

func _angled_shot(angle: float, i: int, skill: Skill) -> void:
	var dir = Vector2(cos(angle), sin(angle)).normalized()
	var projectile = _spawn_projectile(skill, dir)
	if projectile:
		if i % 2 == 0: projectile.play("Fire")
		elif i % 2 == 1: projectile.play("WaterBlast")

func _radial(skill: Skill, count: int) -> void:
	for i in range(count):
		var angle = (float(i) / count) * 2.0 * PI
		_angled_shot(angle, i, skill)

func _spawn_projectile(skill: Skill, dir: Vector2) -> Area2D:
	var proj_node: Node = skill.projectile_scene.instantiate() if skill.projectile_scene else (skill_factory.create() if skill_factory else null)
	if not proj_node: return null
	var proj = proj_node as Area2D
	if proj == null: return null

	if proj.has_method("setup"): proj.setup(skill, dir)
	else:
		if proj.has_variable("speed"): proj.speed = skill.speed
		if proj.has_variable("damage"): proj.damage = skill.damage
		if proj.has_variable("direction"): proj.direction = dir
	proj.global_position = skill_factory.global_position
	get_tree().current_scene.add_child(proj)
	return proj

func _area_shot(skill: Skill, target_position: Vector2, target_enemy: Node2D) -> void:	
	if not skill.area_scene: return
	var area_node: Node = skill.area_scene.instantiate()
	if not area_node: return
	var area_effect = area_node as AreaBase
	get_tree().current_scene.add_child(area_effect)
	area_effect.global_position = target_position
	if area_effect and area_effect.has_method("setup"):
		area_effect.setup(skill, target_position, target_enemy)

func _apply_buff(skill: Skill) -> void: 
	if skill is Fireball: _apply_fireball_buff(skill.duration)
	elif skill is HealOverTime: _apply_heal_over_time(skill.heal_per_tick, skill.duration, skill.tick_interval)

func _apply_fireball_buff(duration: float) -> void:
	enter_fireball()
	await get_tree().create_timer(duration).timeout
	exit_fireball()

func _apply_heal_over_time(heal_amount: float, duration: float, interval: float) -> void:
	var total_ticks: int = floor(duration / interval)
	for i in range(total_ticks):
		if health <= 0: break
		health = min(health + heal_amount, max_health)
		health_changed.emit()
		await get_tree().create_timer(interval).timeout

# ================================================================
# === PHYSICS & LOGIC ============================================
# ================================================================

func _physics_process(delta: float) -> void:
	super._physics_process(delta) # Base character handles visuals now
	
	handle_invulnerable(delta)
	
	# Rigid push logic
	for i in get_slide_collision_count():
		var c = get_slide_collision(i)
		var body = c.get_collider()
		if body is RigidBody2D:
			var normal = -c.get_normal()
			body.apply_central_impulse(normal * push_strength)
	
	debuglabel.text = str(fsm.current_state.name)
			
func handle_invulnerable(delta) -> void:
	if invulnerable_timer > 0:
		invulnerable_timer -= delta
	else:
		if is_invulnerable: hurt_area.collision_layer = saved_collision_layer
		is_invulnerable = false
	
	if is_invulnerable: invulnerable_flicker(delta)
	else: 
		if animated_sprite: animated_sprite.modulate.a = 1

func invulnerable_flicker(delta) -> void:
	flicker_timer += delta
	if flicker_timer >= FLICKER_INTERVAL:
		flicker_timer = 0.0
		if animated_sprite: animated_sprite.modulate.a = 0.3 if animated_sprite.modulate.a > 0.5 else 1.0

func start_atk_cd() -> void:
	is_able_attack = false
	await get_tree().create_timer(atk_cd).timeout
	is_able_attack = true
	
func _cancel_invisibility_if_active() -> void:
	if _is_invisible:
		_on_invisible_ended()

func can_attack() -> bool:
	if not is_able_attack: return false
	_cancel_invisibility_if_active()
	return is_equipped_blade or is_equipped_wand

func can_throw() -> bool: return has_blade && is_equipped_blade

func cast_skill(skill_name: String) -> void:
	if fsm.current_state != fsm.states.castspell: fsm.change_state(fsm.states.castspell)

func set_invulnerable() -> void:
	is_invulnerable = true
	invulnerable_timer = invulnerable_duration
	saved_collision_layer = hurt_area.collision_layer
	hurt_area.collision_layer = 0 

func is_char_invulnerable() -> bool: return is_invulnerable

func jump() -> void:
	super.jump()
	jump_fx_factory.create() as Node2D

func wall_jump() -> void:
	turn_around()
	jump()

func _on_hurt_area_2d_hurt(_direction: Vector2, _damage: float, _elemental_type: int) -> void:
	var modified_damage = calculate_elemental_damage(_damage, _elemental_type)
	fsm.current_state.take_damage(_direction, modified_damage)
	handle_elemental_damage(_elemental_type)
	hurt_particle.emitting = true

# ================================================================
# === SAVE/LOAD & ELEMENTS =======================================
# ================================================================

func save_state() -> Dictionary:
	return { "position": [global_position.x, global_position.y], "health": health, "has_blade": has_blade, "is_in_fireball_state": is_in_fireball_state }

func load_state(data: Dictionary) -> void:
	if data.has("position"): global_position = Vector2(data["position"][0], data["position"][1])
	if data.has("health"): health = clamp(data["health"], 0, max_health); health_changed.emit()
	if data.has("has_blade"):
		has_blade = data["has_blade"]
		if has_blade and not is_in_fireball_state: collected_blade()
	if data.has("is_in_fireball_state"):
		is_in_fireball_state = data["is_in_fireball_state"]
		if is_in_fireball_state: enter_fireball()
		else: exit_fireball()

# ================================================================
# === ELEMENTAL LOGIC REFACTOR ===================================
# ================================================================

func calculate_elemental_damage(base_damage: float, attacker_element: int) -> float:
	if attacker_element == ElementsEnum.Elements.NONE: 
		return base_damage
		
	# Cycle: Metal(1) > Wood(2) > Earth(5) > Water(3) > Fire(4) > Metal(1)
	var advantages = {
		ElementsEnum.Elements.METAL: [ElementsEnum.Elements.WOOD],
		ElementsEnum.Elements.WOOD:  [ElementsEnum.Elements.EARTH],
		ElementsEnum.Elements.EARTH: [ElementsEnum.Elements.WATER],
		ElementsEnum.Elements.WATER: [ElementsEnum.Elements.FIRE],
		ElementsEnum.Elements.FIRE:  [ElementsEnum.Elements.METAL]
	}
	
	# Case 1: Attacker has advantage over Player (Super Effective) -> Take MORE damage
	if advantages.has(attacker_element) and elemental_type in advantages[attacker_element]:
		return base_damage * 1.5 
		
	# Case 2: Player has advantage over Attacker (Resist) -> Take LESS damage
	if advantages.has(elemental_type) and attacker_element in advantages[elemental_type]:
		return base_damage * 0.5 
		
	return base_damage

func handle_elemental_damage(incoming_element: int) -> void:
	match incoming_element:
		ElementsEnum.Elements.FIRE:  apply_fire_effect()
		ElementsEnum.Elements.EARTH: apply_earth_effect()
		ElementsEnum.Elements.WATER: apply_water_effect()
		ElementsEnum.Elements.WOOD:  apply_wood_effect()
		ElementsEnum.Elements.METAL: apply_metal_effect()

# === Status Effect Stubs ===
func apply_fire_effect() -> void: 
	# Example: Burn DOT
	pass

func apply_earth_effect() -> void: 
	# Example: Stun or Slow
	pass

func apply_water_effect() -> void: 
	# Example: Knockback or Wet status
	pass

func apply_wood_effect() -> void:
	# Example: Root/Bind or Poison
	pass

func apply_metal_effect() -> void:
	# Example: Bleed or Armor Break
	pass

func _update_elemental_palette() -> void:
	if not is_instance_valid(animated_sprite): return
	var shader_material = ShaderMaterial.new()
	shader_material.shader = load("res://Scenes/player/player_glowing.gdshader")
	animated_sprite.material = shader_material
	var shader_mat = animated_sprite.material as ShaderMaterial
	shader_mat.set_shader_parameter("elemental_type", elemental_type)
	shader_mat.set_shader_parameter("glow_intensity", 1.5)
	shader_mat.set_shader_parameter("is_fireball_state", is_in_fireball_state)

# ================================================================
# === TARGETING ==================================================
# ================================================================

func _on_detection_area_2d_body_entered(body: Node2D):
	if body.is_in_group("enemies") or body is EnemyCharacter:
		if not _targets_in_range.has(body): _targets_in_range.append(body)

func _on_detection_area_2d_body_exited(body: Node2D):
	if _targets_in_range.has(body): _targets_in_range.erase(body)

func has_valid_target_in_range() -> bool:
	_targets_in_range = _targets_in_range.filter(func(target): return is_instance_valid(target))
	return not _targets_in_range.is_empty()

func get_closest_target() -> Node2D:
	_targets_in_range = _targets_in_range.filter(func(target): return is_instance_valid(target))
	if _targets_in_range.is_empty(): return null
	var closest_target: Node2D = null
	var min_distance_sq: float = INF
	for target in _targets_in_range:
		var distance_sq = global_position.distance_squared_to(target.global_position)
		if distance_sq < min_distance_sq:
			min_distance_sq = distance_sq
			closest_target = target
	return closest_target

# ================================================================
# === MOVEMENT & WEAPON SWAP REFACTOR ============================
# ================================================================

var speed_multiplier: float = 1.0

func set_speed_multiplier(multiplier: float) -> void: speed_multiplier = multiplier
func set_jump_multiplier(multiplier: float) -> void: jump_multiplier = multiplier

func collected_wand() -> void: has_wand = true; _equip_wand_from_swap()
func collected_blade() -> void: has_blade = true; _equip_blade_from_swap()
	
func throw_blade() -> void:
	if is_equipped_wand: return
	var blade = blade_factory.create() as RigidBody2D
	var throw_velocity := Vector2(blade_throw_speed * direction, 0.0)
	blade.apply_impulse(throw_velocity)
	throwed_blade()
	
func throwed_blade() -> void:
	has_blade = false; is_equipped_blade = false
	_set_player_visuals(normal_sprite, silhouette_normal_sprite)
	weapon_swapped.emit("normal")

# ====== VISUAL HELPERS (CORE REFACTOR LOGIC) ======

func _set_player_visuals(new_main_sprite: AnimatedSprite2D, new_silhouette: AnimatedSprite2D) -> void:
	# 1. Update Silhouette list FIRST so the sync logic works on the next frame
	_update_silhouette(new_silhouette)
	
	# 2. Tell BaseCharacter to swap the active sprite
	# This will trigger the _check_changed_animation logic in BaseCharacter
	set_animated_sprite(new_main_sprite)
	
	_update_elemental_palette()

func _update_silhouette(new_silhouette: AnimatedSprite2D) -> void:
	# Hide all known extra sprites immediately
	for s in extra_sprites:
		if is_instance_valid(s): s.hide()
	
	extra_sprites.clear()
	
	# Add the new one to the list so BaseCharacter can sync it
	if new_silhouette:
		extra_sprites.append(new_silhouette)
		new_silhouette.show()

# ====== WEAPON SWAP LOGIC ======

func swap_weapon() -> void:
	if is_in_fireball_state: return
	if not has_blade and not has_wand: return

	if is_equipped_blade:
		if has_wand: _equip_wand_from_swap()
		else: _equip_normal_from_swap()
	elif is_equipped_wand:
		if has_blade: _equip_blade_from_swap()
		else: _equip_normal_from_swap()
	else: # Currently Normal
		if has_blade: _equip_blade_from_swap()
		elif has_wand: _equip_wand_from_swap()

func _equip_blade_from_swap() -> void:
	if is_in_fireball_state: is_equipped_blade = true; is_equipped_wand = false; weapon_swapped.emit("blade"); return
	is_equipped_blade = true; is_equipped_wand = false
	_set_player_visuals(blade_sprite, silhouette_blade_sprite)
	_update_elemental_palette()
	weapon_swapped.emit("blade")
	
func _equip_wand_from_swap() -> void:
	if is_in_fireball_state: is_equipped_wand = true; is_equipped_blade = false; weapon_swapped.emit("wand"); return
	is_equipped_wand = true; is_equipped_blade = false
	_set_player_visuals(wand_sprite, silhouette_wand_sprite)
	_update_elemental_palette()
	weapon_swapped.emit("wand")
	
func _equip_normal_from_swap() -> void:
	if is_in_fireball_state: is_equipped_blade = false; is_equipped_wand = false; weapon_swapped.emit("normal"); return
	is_equipped_blade = false; is_equipped_wand = false
	_set_player_visuals(normal_sprite, silhouette_normal_sprite)
	_update_elemental_palette()
	weapon_swapped.emit("normal")

# ====== FIREBALL STATE (REFACTORED) ======

func enter_fireball() -> void:
	is_in_fireball_state = true 
	fireball_collision.disabled = false
	speed_multiplier = 2.0
	elemental_type = ElementsEnum.Elements.FIRE
	_update_elemental_palette()
	_set_player_visuals(fireball_sprite, null)
	change_animation("Fireball")
	fireball_fx.show()
	fireball_fx.play()
	hurt_area.monitorable = false;
	fireball_hit_area.monitoring = true

func exit_fireball() -> void:
	is_in_fireball_state = false
	fireball_collision.disabled = true
	speed_multiplier = 1.0
	elemental_type = ElementsEnum.Elements.NONE
	_update_elemental_palette()
	fireball_fx.hide()
	fireball_fx.stop()
	fireball_hit_area.monitoring = false;
	hurt_area.monitorable = true 
	
	if is_equipped_blade: _set_player_visuals(blade_sprite, silhouette_blade_sprite)
	elif is_equipped_wand: _set_player_visuals(wand_sprite, silhouette_wand_sprite)
	else: _set_player_visuals(normal_sprite, silhouette_normal_sprite)

func _update_movement(delta: float) -> void:
	if not can_move: velocity = Vector2.ZERO; return
	
	velocity.y += gravity * delta
	
	if fsm.current_state == fsm.states.wallcling: 
		velocity.y = clamp(velocity.y, -INF, wall_slide_speed)
	else: 
		velocity.y = clamp(velocity.y, -INF, max_fall_speed)
	
	if is_dashing: velocity.y = 0
	
	# --- Perform Movement ---
	move_and_slide()

# This function runs whenever the Fireball HitArea touches a HurtArea
func _on_fireball_hit_enemy(hurt_area: Area2D) -> void:
	# Only bounce if we are actually in fireball mode
	if not is_in_fireball_state: return
	
	# 1. Find the Enemy Node
	# Usually the HurtArea is a child of the Enemy, so we get the parent
	var enemy = hurt_area.get_parent() 
	
	if enemy:
		_perform_bounce(enemy.global_position)

func _perform_bounce(enemy_position: Vector2) -> void:
	# 2. Calculate the "Surface Normal"
	# Vector Math: (Destination - Source) = Direction Vector
	# This gives us a vector pointing FROM the enemy TO the player
	var normal_vector = (global_position - enemy_position).normalized()
	
	# 3. Apply the Bounce
	# We use the existing velocity speed, or a minimum bounce speed (300)
	# so you don't lose momentum if you hit them slowly.
	var bounce_speed = max(velocity.length(), 300.0)
	
	# The bounce method reflects the velocity vector off the normal
	velocity = velocity.bounce(normal_vector).normalized() * bounce_speed

func dash() -> void:
	velocity.x = movement_speed * dash_speed_mul * direction
	velocity.y = 0.0
	is_dashing = true; can_dash = false
	await get_tree().create_timer(dash_cd).timeout
	can_dash = true

# FUNC : INVISIBLE GAME STATE

func go_invisible(duration: float) -> void:
	if _invisible_timer:
		_invisible_timer.disconnect("timeout", Callable(self, "_on_invisible_ended"))
		_invisible_timer = null
	
	_is_invisible = true
	
	# Visual fade
	if animated_sprite:
		animated_sprite.modulate.a = 0.3
	for s in extra_sprites:
		if is_instance_valid(s):
			s.modulate.a = 0.3
	
	# Disable taking damage (no enemy hurt)
	hurt_area.monitorable = false
	
	# Make sure player only collides with terrain (mask 1)
	collision_layer = 0 << 1   # Layer 1: terrain
	collision_mask  = 1 << 0   # Mask 1: environment only
	
	_invisible_timer = get_tree().create_timer(duration)
	_invisible_timer.timeout.connect(_on_invisible_ended)

func _on_invisible_ended() -> void:
	_is_invisible = false
	_invisible_timer = null
	
	# Restore visuals
	if animated_sprite:
		animated_sprite.modulate.a = 1.0
	for s in extra_sprites:
		if is_instance_valid(s):
			s.modulate.a = 1.0
	
	# Re‑enable damage detection
	hurt_area.monitorable = true
	
	# Restore original collision setup (layer 2, mask 1)
	collision_layer = 1 << 1   # player
