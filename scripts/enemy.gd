class_name EnemyCharacter
extends BaseCharacter

@onready var damage_number_origin = $DamageNumbersOrigin

@export var particle_audio_interval: float = 1.0  # Seconds between audio plays

var particle_audio_timer: Timer = null

# 0: None, 1: Fire, 2: Water, 3: Earth, 4: Metal, 5: Wood
@export var elements_color : Dictionary[ElementsEnum.Elements, Color] = {
	ElementsEnum.Elements.METAL: Color("f0f0f0"),
	ElementsEnum.Elements.WOOD: Color.LIME_GREEN,
	ElementsEnum.Elements.WATER: Color.AQUA,
	ElementsEnum.Elements.FIRE: Color("ff5219"),
	ElementsEnum.Elements.EARTH: Color("d36f00"),
	ElementsEnum.Elements.NONE: Color.BLACK
}
@export var elements_particle : Dictionary[ElementsEnum.Elements, String] = {
	ElementsEnum.Elements.METAL: "Metal",
	ElementsEnum.Elements.WOOD: "Wood",
	ElementsEnum.Elements.WATER: "Water",
	ElementsEnum.Elements.FIRE: "Fire",
	ElementsEnum.Elements.EARTH: "Earth",
	ElementsEnum.Elements.NONE: "None"
}

@export var elements_debuff: Dictionary[ElementsEnum.Elements, PackedScene]

# Shader that will be used for outlining the enemy based on its element
@export_file("*.gdshader") var shader_path
# Damage deal damage when player touch (HP)
@export var spike: float
# Detect player within this range (radius in pixel)
@export var sight: float
# Can only move within this range (radius in pixel)
@export var movement_range: float
var current_movement_range: float
# Enemy's jump height = jump_speed^2 / 2*gravity (pixel)
@export var jump_height: float
var current_jump_height: float
# Enemy's time on air = jump_speed / gravity
@export var air_time: float
var current_air_time: float
# Enemy's attack speed (pixel/second)
@export var attack_speed: float
var current_attack_speed: float
# Vulnerability determines the percentage of damge the enemy will get when being attacked
@export var vulnerability: float = 0
var current_vulnerability: float

var current_movement_speed: float

var is_frozen: bool = false

# Raycast check wall and fall
var front_ray_cast: RayCast2D
var down_ray_cast: RayCast2D

# Raycast detect player (left / right)
var left_detect_ray: RayCast2D
var right_detect_ray: RayCast2D

# Player reference
var found_player: Player = null

# Spike Hit Area
var spike_hit_area: HitArea2D = null

# Material to change outline
var shader_material: Material

# Enemy can only move in a range around this position
var start_position: Vector2

var current_particle: GPUParticles2D

var debuff_place_holder: Node2D
var current_debuff: Debuff

func _ready() -> void:
	_init_current_values()
	super._ready()
	_init_culling()
	_init_ray_cast()
	_init_detect_player_raycast()
	_init_hurt_area()
	_init_hit_area()
	_init_material()
	_init_start_position()
	_init_particle()
	_init_debuff()
	
	#current_debuff = Debuff.new(self)
	#add_child(current_debuff)
	
	add_to_group("enemies")
	
	var minimap = GameManager.minimap
	
	if minimap:
		# 2. Register self. MUST match the key in 'group_settings' ("enemies")
		minimap.register_object("enemies", self)
	
	# Connect to global particle quality signal (check if not already connected)
	if not SettingsManager.particle_quality_changed.is_connected(_on_particle_quality_changed):
		SettingsManager.particle_quality_changed.connect(_on_particle_quality_changed)
	
	# Use global interval value
	particle_audio_interval = SettingsManager.particle_audio_interval

func _init_debuff():
	if has_node("DebuffPlaceHolder"):
		debuff_place_holder = $DebuffPlaceHolder
		if debuff_place_holder == null: print ("Please assign a debuff place holder for enemy")
	else: print ("Please assign a debuff place holder for enemy")
	current_debuff = null

# -- Initialize current values
func _init_current_values():
	current_movement_speed = movement_speed
	current_movement_range = movement_range
	current_jump_height = jump_height
	current_air_time = air_time
	current_attack_speed = attack_speed
	current_vulnerability = vulnerability

# -- Initialize start position
func _init_start_position():
	start_position = position

# -- Initialize material
func _init_material():
	shader_material = ShaderMaterial.new()
	if shader_path == null: return
	var my_shader = load(shader_path)
	if my_shader != null:
		shader_material.shader = my_shader
	
	var outline_color = elements_color[elemental_type]
	if outline_color == null: return
	shader_material.set("shader_parameter/line_color", outline_color)
	pass

# --- Initialize element outline
func _update_element_outline():
	if animated_sprite == null: return
	if animated_sprite.material != shader_material: animated_sprite.material = shader_material
	pass

func _check_changed_animation() -> void:
	super._handle_visual_updates()
	_update_element_outline()

# --- Initialize raycasts for wall/fall detection
func _init_ray_cast():
	if has_node("Direction/FrontRayCast2D"):
		front_ray_cast = $Direction/FrontRayCast2D
	if has_node("Direction/DownRayCast2D"):
		down_ray_cast = $Direction/DownRayCast2D

# --- Initialize raycasts for detecting player
func _init_detect_player_raycast():
	if has_node("Direction/LeftDetectRayCast2D"):
		left_detect_ray = $Direction/LeftDetectRayCast2D
		left_detect_ray.target_position = Vector2(-sight, 0)
	if has_node("Direction/RightDetectRayCast2D"):
		right_detect_ray = $Direction/RightDetectRayCast2D
		right_detect_ray.target_position = Vector2(sight, 0)

# --- Initialize hurt area
func _init_hurt_area():
	if has_node("Direction/HurtArea2D"):
		var hurt_area = $Direction/HurtArea2D
		hurt_area.hurt.connect(_on_hurt_area_2d_hurt)

# --- Initialize hit area
func _init_hit_area():
	if has_node("Direction/SpikeHitArea2D"):
		spike_hit_area = $Direction/SpikeHitArea2D
		spike_hit_area.damage = spike
		spike_hit_area.elemental_type = elemental_type

func _init_particle():
	if has_node("Particles"):
		var particle_holder = $Particles
		if particle_holder.get_child_count() == 0:
			return
			
		var particles: Array = particle_holder.get_children()
		for particle in particles:
			if particle == null: continue
			if particle is GPUParticles2D:
				var particle_name: String = particle.name
				if particle_name == elements_particle[elemental_type]:
					if current_particle != null:
						current_particle.emitting = false
					current_particle = particle
					if current_particle != null:
						# Apply initial quality setting
						_apply_particle_quality()
						current_particle.emitting = true
						_setup_particle_audio()

func _apply_particle_quality() -> void:
	if current_particle == null:
		return
	
	var ratio = SettingsManager.get_particle_ratio()
	current_particle.amount_ratio = ratio
	
	# Optionally disable emitting entirely for OFF quality
	if SettingsManager.particle_quality == SettingsManager.ParticleQuality.OFF:
		current_particle.emitting = false
	elif not current_particle.emitting:
		current_particle.emitting = true

func _on_particle_quality_changed(_quality: int) -> void:
	_apply_particle_quality()

func _setup_particle_audio():
	if not AudioManager or not AudioManager.audio_database:
		return
	
	var audio_id: String = ""
	
	match elemental_type:
		ElementsEnum.Elements.NONE:
			audio_id = "particle_none"
		ElementsEnum.Elements.METAL:
			audio_id = "particle_metal"
		ElementsEnum.Elements.WOOD:
			audio_id = "particle_wood"
		ElementsEnum.Elements.WATER:
			audio_id = "particle_water"
		ElementsEnum.Elements.FIRE:
			audio_id = "particle_fire"
		ElementsEnum.Elements.EARTH:
			audio_id = "particle_earth"
	
	if audio_id == "":
		return
	
	var particle_sfx: AudioStreamPlayer2D = null
	if current_particle.has_node("AudioStreamPlayer2D"):
		particle_sfx = current_particle.get_node("AudioStreamPlayer2D")
	else:
		particle_sfx = AudioStreamPlayer2D.new()
		current_particle.add_child(particle_sfx)
	
	var audio_clip = AudioManager.audio_database.get_clip(audio_id)
	if audio_clip:
		# Set constant properties once
		particle_sfx.volume_db = audio_clip.volume_db
		particle_sfx.max_distance = 300
		particle_sfx.autoplay = false
		
		# Pass the clip to the timer setup so we can access variations later
		_start_particle_audio_timer(particle_sfx, audio_clip)

func _start_particle_audio_timer(audio_player: AudioStreamPlayer2D, audio_clip: AudioClip) -> void:
	# Clean up existing timer if any
	if particle_audio_timer:
		particle_audio_timer.stop()
		particle_audio_timer.queue_free()
	
	# Create new timer
	particle_audio_timer = Timer.new()
	particle_audio_timer.name = "ParticleAudioTimer"
	add_child(particle_audio_timer)
	particle_audio_timer.wait_time = particle_audio_interval
	particle_audio_timer.one_shot = false
	
	# BINDING: We pass both the player AND the clip to the timeout function
	particle_audio_timer.timeout.connect(_on_particle_audio_timer_timeout.bind(audio_player, audio_clip))
	
	particle_audio_timer.start()
	
	# Play immediately (using the helper logic manually for the first time)
	_play_with_variation(audio_player, audio_clip)

func _on_particle_audio_timer_timeout(audio_player: AudioStreamPlayer2D, audio_clip: AudioClip) -> void:
	if audio_player and is_instance_valid(audio_player):
		_play_with_variation(audio_player, audio_clip)

# Shared helper to apply random stream and pitch before playing
func _play_with_variation(player: AudioStreamPlayer2D, clip: AudioClip) -> void:
	# 1. Get a random stream variation using the helper you added
	player.stream = clip.get_playback_stream()
	
	# 2. Apply random pitch (since we are resetting the play, we should re-roll pitch too)
	if clip.randomize_pitch:
		player.pitch_scale = randf_range(clip.pitch_min, clip.pitch_max)
	else:
		player.pitch_scale = 1.0
		
	player.play()

func _init_culling() -> void:
	# Create enabler programmatically
	var enabler = VisibleOnScreenEnabler2D.new()
	add_child(enabler)
	
	# Get viewport size to extend culling area
	if is_inside_tree():
		_setup_culling_rect(enabler)
	else:
		call_deferred("_setup_culling_rect", enabler)

func _setup_culling_rect(enabler: VisibleOnScreenEnabler2D) -> void:
	var viewport_size: Vector2 = get_viewport_rect().size

	# Fallback size if viewport_size is invalid / zero
	if viewport_size == Vector2.ZERO:
		viewport_size = Vector2(1280, 720)  # your fallback resolution

	# Extend the rect to 2x viewport size
	var extended_rect := Rect2(
		-viewport_size,          # position
		viewport_size * 3.0      # size
	)

	enabler.rect = extended_rect
	enabler.enable_mode = VisibleOnScreenEnabler2D.ENABLE_MODE_INHERIT

# --- Check if touching wall
func is_touch_wall() -> bool:
	return front_ray_cast != null and front_ray_cast.is_colliding()
	
# --- Check if can fall
func is_can_fall() -> bool:
	return down_ray_cast != null and not down_ray_cast.is_colliding()


func _process(delta):
	if not is_visible_in_tree():
		return

# --- Called every frame (or physics frame)
func _physics_process(delta: float) -> void:
	super._physics_process(delta)
	_check_player_in_sight()
	process_debuff(delta)

func process_debuff(delta: float) -> void:
	if current_debuff == null: return
	current_debuff._update(delta)
	pass

# --- Check player detection via raycast
func _check_player_in_sight():
	var detected_player := _get_player_from_raycasts()
	
	if detected_player != found_player:
		if detected_player:
			found_player = detected_player
			_on_player_in_sight(found_player.global_position)
		else:
			_on_player_not_in_sight()
			found_player = null

# --- Helper: returns player if any raycast hit it
func _get_player_from_raycasts() -> Player:
	if left_detect_ray and left_detect_ray.is_colliding():
		var collider = left_detect_ray.get_collider()
		if collider is Player:
			return collider

	if right_detect_ray and right_detect_ray.is_colliding():
		var collider = right_detect_ray.get_collider()
		if collider is Player:
			return collider

	return null


# --- Called when player is in sight
func _on_player_in_sight(_player_pos: Vector2) -> void:
	#print("Player detected at:", _player_pos)
	pass

# --- Called when player is not in sight
func _on_player_not_in_sight() -> void:
	#print("Player lost from sight")
	pass

# --- When enemy takes damage
func _on_hurt_area_2d_hurt(_direction: Vector2, _damage: float, _elemental_type: int) -> void:
	# Demo debuff
	#var debuff: PackedScene = load("res://scenes/enemies/debuffs/FreezeDebuff/freeze_debuff.tscn") as PackedScene
	#set_debuff(debuff)
	
	# Tính damage dựa trên quan hệ sinh - khắc
	var modified_damage = calculate_elemental_damage(_damage, _elemental_type)
	modified_damage += modified_damage * current_vulnerability
	#print(elemental_type)
	var is_critical = (check_element(_elemental_type, elemental_type) == -1)
	print("my element: " + str(elemental_type) + " enemy: " + str(_elemental_type) + " is critical: " + str(is_critical))
	DamageNumbers.display_number(modified_damage, damage_number_origin.global_position, is_critical)
	if (fsm.current_state != null): fsm.current_state.take_damage(_direction, modified_damage)
	handle_elemental_damage(_elemental_type)

func calculate_elemental_damage(base_damage: float, attacker_element: int) -> float:
	var check_element = check_element(attacker_element, elemental_type)
	match check_element:
		# Bị khắc
		-1: return base_damage * 1.25
		# Không sinh khắc
		0: return base_damage
		# Được sinh
		1: return base_damage * 0.75
	
	return base_damage

func check_element(elemental_type_1: ElementsEnum.Elements, elemental_type_2: ElementsEnum.Elements) -> int:
	# 1 khắc 2
	if (restraint_table.has(elemental_type_1) and restraint_table[elemental_type_1].has(elemental_type_2)):
		return -1
	# 1 sinh 2
	if (creation_table.has(elemental_type_1) and creation_table[elemental_type_1].has(elemental_type_2)):
		return 1
	# Không sinh khắc
	return 0

func handle_elemental_damage(attacker_element: ElementsEnum.Elements) -> void:
	var debuff_scene: PackedScene = null
	if elements_debuff.has(attacker_element):
		debuff_scene = elements_debuff[attacker_element]
	if debuff_scene == null: return
	set_debuff(debuff_scene)


func apply_burn_effect() -> void:
	# Có thể thêm hiệu ứng lửa (burn status, animation, etc)
	print("Burn")
	pass

func apply_freeze_effect() -> void:
	# Có thể thêm hiệu ứng đất (slow, knockback, etc)
	print("Freeze")
	pass

func apply_stun_effect() -> void:
	# Có thể thêm hiệu ứng nước (freeze, slow, etc)
	print("Stunned")
	pass

func apply_poison_effect() -> void:
	print("Poisoned")
	pass
	
func apply_weakness_effect() -> void:
	print("Weakness")
	pass


# --- Apply damage through FSM
func _take_damage_from_dir(_damage_dir: Vector2, _damage: float):
	fsm.current_state.take_damage(_damage_dir, _damage)

# -- Disable collision, enemy will no longer has collision with player
func disable_collision():
	collision_layer = 0
	if spike_hit_area != null and spike_hit_area.has_node("CollisionShape2D"):
		spike_hit_area.get_node("CollisionShape2D").disabled = true

# Enemy bị hút vào vùng nổ
func enter_tornado(tornado_pos: Vector2) -> void:
	# 1. Thiết lập trạng thái
	is_movable = false
	velocity = Vector2.ZERO
	
	# 3. Bắt đầu hiệu ứng "bay lên"
	var target_pos = tornado_pos + Vector2(0, -30)
	var duration = 0.5
	
	var tween := get_tree().create_tween()
	
	tween.tween_property(
		self,
		"global_position",
		target_pos,
		duration
	).set_trans(Tween.TRANS_SPRING).set_ease(Tween.EASE_OUT)
	
# Enemy bị hút vào vùng nổ
func enter_stun(stun_pos: Vector2) -> void:
	# 1. Thiết lập trạng thái
	is_movable = false
	velocity = Vector2.ZERO

# Khi rời khỏi
func exit_skill() -> void:
	# Khôi phục khả năng di chuyển
	is_movable = true
	velocity = Vector2.ZERO
	
func apply_knockback(knockback_vec: Vector2):
	velocity = knockback_vec
	ignore_gravity = true
	await get_tree().create_timer(0.25).timeout
	ignore_gravity = false
	
	
# Add to ALL Enemy scripts:
func scale_health(multiplier: float):
	if not has_node("EnemyHealthBar"): return  # Safety check
	max_health *= multiplier
	health = max_health
	print("💚 %s: %.0fHP (x%.1f)" % [name, max_health, multiplier])

func _exit_tree():
	# 3. Clean up when enemy dies so the icon disappears immediately
	var minimap = get_tree().get_first_node_in_group("Minimap")
	if minimap:
		minimap.remove_object("enemies", self)

# Functions for debuff
func set_debuff(debuff_scene: PackedScene) -> void:
	print("debuff: " + str(debuff_scene))
	if current_debuff != null: return
	if debuff_scene == null: return
	if debuff_place_holder == null: return
	var debuff: Debuff = (debuff_scene.instantiate() as Debuff)
	if debuff == null: return
	debuff.init(self)
	debuff_place_holder.add_child(debuff)
	debuff.position = Vector2.ZERO
	current_debuff = debuff

func remove_debuff(debuff: Debuff) -> void:
	if current_debuff == null: return
	if debuff_place_holder == null: return
	if debuff == current_debuff:
		debuff_place_holder.remove_child(current_debuff)
		current_debuff = null

func set_is_blind(value: bool) -> void:
	if value == true:
		if front_ray_cast != null: front_ray_cast.enabled = false
		#if down_ray_cast != null: down_ray_cast.enabled = false
		if right_detect_ray != null: right_detect_ray.enabled = false
		if left_detect_ray != null: left_detect_ray.enabled = false
		found_player = null
	else:
		if front_ray_cast != null: front_ray_cast.enabled = true
		#if down_ray_cast != null: down_ray_cast.enabled = true
		if right_detect_ray != null: right_detect_ray.enabled = true
		if left_detect_ray != null: left_detect_ray.enabled = true

func set_vulnerability(value: float) -> void:
	current_vulnerability = value
func reset_vulnerability() -> void:
	current_vulnerability = vulnerability
	
func freeze_in_place(value: bool) -> void:
	#if value == true: current_movement_speed = 0
	#else: current_movement_speed = movement_speed
	is_frozen = value
	velocity.x = 0
	if animated_sprite != null:
		if value == true: animated_sprite.speed_scale = 0
		else: animated_sprite.speed_scale = 1
