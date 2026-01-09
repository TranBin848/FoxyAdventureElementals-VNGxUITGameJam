class_name EarthquakeProjectile
extends ProjectileBase

@export_group("Spawner Settings")
@export var wave_count_base: int = 5
@export var spawn_interval: float = 0.05
@export var segment_scene_path: String # MUST ASSIGN THIS IN EDITOR

var segment_scene: PackedScene
var segments_spawned: int = 0
var current_wave_target: int = 0
var is_stopped: bool = false

func _ready() -> void:
	# Only do configuration here, don't start logic yet
	collision_layer = 0 
	collision_mask = 1 
	
	AudioManager.play_sound("skill_earthquake")
	
	# REMOVED: _start_spawn_routine() 

func setup(skill: Skill, dir: Vector2) -> void:
	super.setup(skill, dir)
	
	# 1. Calculate the target
	self.current_wave_target = (wave_count_base * (1.0 + sqrt(skill.level - 1.0)))
	
	# Debug print to verify
	# print("Target: ", current_wave_target, " | Base: ", wave_count_base, " | Lvl: ", skill.level)
	
	segment_scene = load(segment_scene_path)
	
	speed = skill.speed
	elemental_type = skill.elemental_type
	
	# 2. NOW start the routine, guaranteed to have data
	_start_spawn_routine()

func _physics_process(delta: float) -> void:
	if is_stopped: return
	super._physics_process(delta)

# Detect Wall Collision
func _on_body_entered(body: Node2D) -> void:
	# If we hit a wall/terrain
	if body is TileMapLayer or body.is_in_group("terrain"):
		_spawn_segment() # Spawn one last one at the wall
		_stop_projectile()

func _start_spawn_routine() -> void:
	if not segment_scene:
		push_error("EarthquakeProjectile: No Segment Scene assigned!")
		queue_free()
		return

	while segments_spawned < current_wave_target and not is_stopped:
		_spawn_segment()
		segments_spawned += 1
		
		# Wait for the stagger time before moving and spawning the next
		await get_tree().create_timer(spawn_interval).timeout
		
		# Safety check: If we died/stopped while waiting
		if not is_inside_tree(): return

	# Done spawning
	_stop_projectile()

func _spawn_segment() -> void:
	var segment = segment_scene.instantiate() as EarthquakeSegment
	get_tree().current_scene.add_child(segment)
	segment.global_position = global_position
	
	# 1. Set the Data
	segment.damage = damage
	segment.elemental_type = elemental_type
	segment.direction = direction 
	
	# 2. Update the Visuals NOW (because we just set the direction)
	if segment.has_method("update_facing_visuals"):
		segment.update_facing_visuals()

func _stop_projectile() -> void:
	is_stopped = true
	set_physics_process(false)
	queue_free()
