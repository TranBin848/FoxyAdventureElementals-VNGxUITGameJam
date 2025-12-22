extends AreaBase
class_name CometRainArea

@export var comet_scene_path: String = ""
@export var comets_count: int = 32
@export var spawn_height: float = 800.0
@export var area_width: float = 160.0
@export var spawn_interval: float = 0.05
@export var fall_angle_deg: float = 45.0
@export var base_speed: float = 500.0
@export var speed_random_ratio: float = 0.2

# NEW: How far in front of the player the rain centers
@export var forward_offset: float = 160.0 
# NEW: How high above the ground collision becomes active
@export var collision_arming_offset: float = 160.0 

var comet_scene: PackedScene

func setup(skill: Skill, caster_position: Vector2, _enemy: EnemyCharacter, _direction: Vector2 = Vector2.RIGHT) -> void:
	print("[RainArea] Setup started. Caster Pos: ", caster_position)
	self.damage = skill.damage
	self.elemental_type = skill.elemental_type
	self.duration = skill.duration
	self.direction = _direction
	
	# --- CHANGE 1: Offset the Area Position ---
	# Ensure direction is normalized (length 1) then multiply by offset
	var offset_vec = direction.normalized() * forward_offset
	# If direction is zero (rare edge case), default to right
	if direction == Vector2.ZERO: offset_vec = Vector2(forward_offset, 0)
	
	self.global_position = caster_position + offset_vec
	# ------------------------------------------

	comet_scene = load(comet_scene_path)
	
	if not comet_scene:
		push_error("[RainArea] Failed to load comet scene at: " + comet_scene_path)
		return
		
	_start_comet_rain()
	_setup_duration_timer()

func _start_comet_rain() -> void:
	print("[RainArea] Starting rain. Count: ", comets_count)
	for i in range(comets_count):
		_spawn_one_comet()
		await get_tree().create_timer(spawn_interval).timeout

func _spawn_one_comet() -> void:
	if not comet_scene:
		return
	
	# 1. Determine Target
	var half_w := area_width * 0.5
	var target_x := global_position.x + randf_range(-half_w, half_w)
	var target_y := global_position.y 
	var target_pos := Vector2(target_x, target_y)
	
	# 2. Calculate Spawn Position
	var angle_rad := deg_to_rad(abs(fall_angle_deg))
	var offset_x := spawn_height * tan(angle_rad)
	
	var spawn_x := target_x - offset_x
	var spawn_y := target_y - spawn_height
	spawn_x += randf_range(-50.0, 50.0)
	
	var spawn_pos := Vector2(spawn_x, spawn_y)

	# 3. Instantiate
	var comet := comet_scene.instantiate() as CometProjectile
	if comet == null:
		push_error("[RainArea] Failed to instantiate comet!")
		return

	var t_time := randf_range(0.8, 1.2)
	comet.travel_time = t_time
	comet.arc_height = randf_range(0.0, 30.0)
	
	# --- CHANGE 2: Pass the Arming Height ---
	# We use the Target Y (ground level) minus the offset.
	# Collisions are ignored ABOVE this Y value.
	comet.arming_height = target_y - collision_arming_offset
	# ----------------------------------------

	comet.setup(spawn_pos, target_pos, damage, elemental_type)
	
	# Safe parent lookup
	var parent_scene = get_parent()
	if parent_scene:
		parent_scene.add_child(comet)
	else:
		get_tree().root.add_child(comet)
		print("[RainArea] Parent not found, added to Root.")

func _on_startup_complete() -> void:
	_disable_hitbox() 

func _apply_stun_effect() -> void:
	_disable_hitbox()
