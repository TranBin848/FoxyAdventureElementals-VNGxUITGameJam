# ============================================================================
# CometRainArea.gd - Direction-Aware
# ============================================================================
extends AreaBase
class_name CometRainArea

@export var comet_scene_path: String = ""
@export var comets_count: int = 12
@export var spawn_height: float = 800.0
@export var area_width: float = 160.0
@export var spawn_interval: float = 0.02
@export var fall_angle_deg: float = 45.0
@export var base_speed: float = 500.0
@export var speed_random_ratio: float = 0.2
@export var forward_offset: float = 160.0 
@export var collision_arming_offset: float = 160.0 

var comet_scene: PackedScene

func setup(skill: Skill, caster_position: Vector2, _enemy: EnemyCharacter, _direction: Vector2 = Vector2.RIGHT) -> void:
	# Use scaled damage from skill
	self.damage = skill.get_scaled_damage()
	self.elemental_type = skill.elemental_type
	self.duration = skill.get_scaled_duration()
	self.direction = _direction
	
	# Scale comet count
	self.comets_count = int(comets_count * skill._calculate_scale())
	
	# Position area in front of player based on direction
	var offset_vec = direction.normalized() * forward_offset
	if direction == Vector2.ZERO:
		offset_vec = Vector2(forward_offset, 0)
	
	self.global_position = caster_position + offset_vec
	
	comet_scene = load(comet_scene_path)
	if not comet_scene:
		push_error("[RainArea] Failed to load comet scene at: " + comet_scene_path)
		return
		
	_start_comet_rain()
	_setup_duration_timer()

func _start_comet_rain() -> void:
	AudioManager.play_sound("skill_comet_rain")
	for i in range(comets_count):
		_spawn_one_comet()
		await get_tree().create_timer(spawn_interval).timeout

func _spawn_one_comet() -> void:
	if not comet_scene:
		return
	
	var half_w := area_width * 0.5
	var target_x := global_position.x + randf_range(-half_w, half_w)
	var target_y := global_position.y 
	var target_pos := Vector2(target_x, target_y)
	
	# Calculate angle offset based on player's facing direction
	var angle_rad := deg_to_rad(abs(fall_angle_deg))
	var offset_x := spawn_height * tan(angle_rad)
	
	# Make comets fall FROM BEHIND the player TOWARD their facing direction
	var spawn_x: float
	if direction.x >= 0:
		# Facing right: spawn comets to the LEFT so they fall RIGHT
		spawn_x = target_x - offset_x
	else:
		# Facing left: spawn comets to the RIGHT so they fall LEFT
		spawn_x = target_x + offset_x
	
	var spawn_y := target_y - spawn_height
	spawn_x += randf_range(-50.0, 50.0)
	
	var spawn_pos := Vector2(spawn_x, spawn_y)
	
	var comet := comet_scene.instantiate() as CometProjectile
	if comet == null:
		push_error("[RainArea] Failed to instantiate comet!")
		return
	
	# ADD TO TREE FIRST so @onready variables are assigned
	var parent_scene = get_parent()
	if parent_scene:
		parent_scene.add_child(comet)
	else:
		get_tree().root.add_child(comet)
	
	# NOW call setup - hit_area will be available
	var t_time := randf_range(0.8, 1.2)
	comet.travel_time = t_time
	comet.arc_height = randf_range(0.0, 30.0)
	comet.arming_height = target_y - collision_arming_offset
	comet.setup(spawn_pos, target_pos, damage, elemental_type)

func _on_startup_complete() -> void:
	_disable_hitbox() 

func _apply_stun_effect() -> void:
	_disable_hitbox()
