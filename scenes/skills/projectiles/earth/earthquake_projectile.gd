class_name EarthquakeProjectile
extends ProjectileBase

@export_group("Spawner Settings")
@export var wave_count_base: int = 3
@export var spawn_interval: float = 0.05
@export var segment_scene_path: String

var segment_scene: PackedScene
var segments_spawned: int = 0
var current_wave_target: int = 0
var is_stopped: bool = false

func _ready() -> void:
	collision_layer = 0 
	collision_mask = 1 
	AudioManager.play_sound("skill_earthquake")

func setup(_skill: Skill, dir: Vector2) -> void:
	super.setup(_skill, dir)
	
	# Scale wave count using skill's scaling
	self.current_wave_target = int(wave_count_base * skill._calculate_scale())
	
	segment_scene = load(segment_scene_path)
	speed = skill.speed
	elemental_type = skill.elemental_type
	
	_start_spawn_routine()

func _physics_process(delta: float) -> void:
	if is_stopped:
		return
	super._physics_process(delta)

func _on_body_entered(body: Node2D) -> void:
	if body is TileMapLayer or body.is_in_group("terrain"):
		_spawn_segment()
		_stop_projectile()

func _start_spawn_routine() -> void:
	if not segment_scene:
		push_error("EarthquakeProjectile: No Segment Scene assigned!")
		queue_free()
		return

	while segments_spawned < current_wave_target and not is_stopped:
		_spawn_segment()
		segments_spawned += 1
		
		await get_tree().create_timer(spawn_interval).timeout
		
		if not is_inside_tree():
			return

	_stop_projectile()

func _spawn_segment() -> void:
	var segment = segment_scene.instantiate() as EarthquakeSegment
	get_tree().current_scene.add_child(segment)
	segment.global_position = global_position
	
	# Pass scaled damage from parent projectile
	segment.damage = damage  # This is already scaled from ProjectileBase.setup()
	segment.elemental_type = elemental_type
	segment.direction = direction 
	
	# Setup the segment's HitArea if it has one
	if segment.has_method("setup_hit_area"):
		segment.setup_hit_area()
	
	if segment.has_method("update_facing_visuals"):
		segment.update_facing_visuals()

func _stop_projectile() -> void:
	is_stopped = true
	set_physics_process(false)
	queue_free()
