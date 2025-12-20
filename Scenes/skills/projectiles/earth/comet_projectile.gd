extends Node2D
class_name CometProjectile

@export var travel_time: float = 1.0
@export var arc_height: float = 20.0
@export var damage: int = 0
@export var elemental_type: ElementsEnum.Elements = ElementsEnum.Elements.NONE
@export var crater_scene: PackedScene
@export var floor_dot_threshold: float = 0.7

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var hit_area: HitArea2D = $HitArea2D if has_node("HitArea2D") else null
@onready var ground_area: Area2D = $GroundHitArea2D
@onready var ground_ray: RayCast2D = $RayCast2D

var A: Vector2 
var B: Vector2 
var C: Vector2 
var elapsed: float = 0.0
var active: bool = false
var last_position: Vector2

# NEW variable to store the height threshold
var arming_height: float = -99999.0 

func setup(start_pos: Vector2, end_pos: Vector2, damage_amount: int, elem_type: ElementsEnum.Elements) -> void:
	A = start_pos
	C = end_pos
	damage = damage_amount
	elemental_type = elem_type
	
	var bias_point = A.lerp(C, 0.2) 
	B = bias_point + Vector2(0, -arc_height)
	
	global_position = A
	last_position = global_position
	elapsed = 0.0
	active = true
	
	print("[Comet] Created at %s. Aiming for %s" % [A, C])
	
	if hit_area:
		hit_area.damage = damage
		hit_area.elemental_type = elemental_type
		hit_area.monitoring = true
		if not hit_area.area_entered.is_connected(_on_hit_something):
			hit_area.area_entered.connect(_on_hit_something)
	else:
		push_warning("[Comet] No HitArea2D found!")
	
	if ground_area:
		if not ground_area.body_entered.is_connected(_on_ground_body_entered):
			ground_area.body_entered.connect(_on_ground_body_entered)
	
	if sprite and sprite.sprite_frames.has_animation("Comet_Fly"):
		sprite.play("Comet_Fly")

func _physics_process(delta: float) -> void:
	if not active:
		return
	
	elapsed += delta
	
	# 1. Timeout Failsafe
	if elapsed > 10.0:
		push_warning("[Comet] Timed out (10s) without hitting anything. Deleting.")
		queue_free()
		return

	# 2. Calculate NEXT Position
	var t: float = elapsed / max(travel_time, 0.01)
	
	var p1 := A.lerp(B, t)
	var p2 := B.lerp(C, t)
	var next_pos := p1.lerp(p2, t)
	
	var motion_vector: Vector2 = next_pos - global_position
	var motion_len = motion_vector.length()

	# 3. RayCast Logic
	var hit_ground = false
	
	# --- CHECK: Only check collisions if we are below the arming height ---
	# (Remember in Godot, larger Y means lower down)
	if global_position.y >= arming_height:
		
		if ground_ray and motion_len > 0.0:
			ground_ray.position = Vector2.ZERO
			ground_ray.global_rotation = 0 
			ground_ray.target_position = motion_vector
			
			if hit_area: ground_ray.add_exception(hit_area)
			if ground_area: ground_ray.add_exception(ground_area)
			
			ground_ray.force_raycast_update()
			
			if ground_ray.is_colliding():
				var normal = ground_ray.get_collision_normal()
				var dot = normal.dot(Vector2.UP)
				
				if dot > floor_dot_threshold:
					# FLOOR HIT
					print("[Comet] Valid Floor Hit! Spawning crater.")
					_spawn_crater_at(ground_ray.get_collision_point())
					global_position = ground_ray.get_collision_point()
					_on_reach_target(false)
					hit_ground = true
				
				elif dot < -0.1:
					# CEILING HIT (Ignore)
					print("[Comet] Hit Ceiling (Dot: %f). Ignoring." % dot)
					
				else:
					# WALL HIT
					print("[Comet] Wall Hit! (Dot: %f). Exploding." % dot)
					global_position = ground_ray.get_collision_point()
					_on_reach_target(false) 
					hit_ground = true
	
	if hit_ground:
		return 

	# 4. Commit Movement
	last_position = next_pos
	global_position = next_pos
	
	# 5. Rotation
	if motion_len > 0.1:
		rotation = motion_vector.angle() 

func _on_hit_something(_area_or_body) -> void:
	if not active: return
	
	# --- CHECK: Ignore enemies if we are too high up ---
	if global_position.y < arming_height:
		return

	print("[Comet] Hit Enemy/Target! Exploding.")
	_on_reach_target(true) 
		
func _on_ground_body_entered(_body: Node) -> void:
	if not active: return
	
	# --- CHECK: Ignore ground bodies (like tall walls) if too high up ---
	if global_position.y < arming_height:
		return
	
	if not ground_ray or not ground_ray.is_colliding():
		_on_reach_target(false) 
		return
	
	var normal: Vector2 = ground_ray.get_collision_normal()
	var dot: float = normal.dot(Vector2.UP)
	
	if dot > floor_dot_threshold:
		print("[Comet] GroundArea confirmed FLOOR hit.")
		_spawn_crater_at(ground_ray.get_collision_point())
	else:
		print("[Comet] GroundArea confirmed WALL hit.")
	
	_on_reach_target(false)

func _spawn_crater_at(pos: Vector2) -> void:
	if crater_scene == null:
		print("[Comet] No crater scene assigned.")
		return
	
	var crater := crater_scene.instantiate()
	if crater is Node2D:
		crater.global_position = pos
	get_tree().current_scene.add_child(crater)

func _on_reach_target(force_crater: bool) -> void:
	if not active:
		return
	
	active = false
	
	if force_crater and crater_scene:
		_spawn_crater_at(global_position)
	
	if sprite and sprite.sprite_frames.has_animation("Comet_End"):
		print("[Comet] Playing End Animation.")
		sprite.play("Comet_End")
		sprite.animation_finished.connect(_on_animation_finished, CONNECT_ONE_SHOT)
	else:
		print("[Comet] No End anim, freeing immediately.")
		queue_free()

func _on_animation_finished() -> void:
	queue_free()
