extends Node2D
class_name SwordProjectile

@export var travel_time: float = 0.6 # Faster flight for direct attacks
@export var damage: int = 0
@export var elemental_type: int = 0

# Visuals
@onready var sprite: Sprite2D = $Sprite2D # Assuming Sprite Sheet method
@onready var hit_area: HitArea2D = $HitArea2D
@onready var ground_ray: RayCast2D = $RayCast2D

# Movement Variables
var start_pos: Vector2 
var target_pos: Vector2 
var elapsed: float = 0.0
var active: bool = false # Determines if it is flying
var is_stuck: bool = false
var stick_duration: float = 5.0

func setup_hover(pos: Vector2, dmg: int, elem: int, duration: float) -> void:
	# 1. Initialize stats but DO NOT MOVE
	damage = dmg
	elemental_type = elem
	stick_duration = duration
	
	global_position = pos
	active = false
	is_stuck = false
	
	# Setup HitArea (but disable monitoring until launch to be safe)
	if hit_area:
		hit_area.damage = damage
		hit_area.elemental_type = elemental_type
		hit_area.monitoring = false 
		if not hit_area.area_entered.is_connected(_on_hit_something):
			hit_area.area_entered.connect(_on_hit_something)

func launch(target: Vector2) -> void:
	# 2. Start the Attack
	start_pos = global_position
	target_pos = target
	
	# Rotate to face target immediately
	var dir = (target_pos - start_pos).normalized()
	rotation = dir.angle() + PI/2 # Adjust based on sprite orientation
	
	elapsed = 0.0
	active = true
	
	if hit_area: hit_area.monitoring = true

func _physics_process(delta: float) -> void:
	if not active or is_stuck: return
	
	elapsed += delta
	
	# --- Linear Flight Logic (Simpler than Bezier for direct shots) ---
	var t: float = elapsed / travel_time
	
	if t > 1.0:
		# Overshoot logic: Keep flying past the target point
		# We essentially just extrapolate the vector
		var velocity = (target_pos - start_pos) / travel_time
		global_position += velocity * delta
	else:
		# Interpolate to target
		global_position = start_pos.lerp(target_pos, t)
	
	# --- RayCast Ground Logic (Same as before) ---
	# (Simplified for brevity, ensure you keep your Wall/Floor check here)
	if ground_ray:
		ground_ray.target_position = Vector2(0, 32).rotated(-rotation) # Local Down
		if ground_ray.is_colliding():
			_stick_to_ground(ground_ray.get_collision_point())

func _stick_to_ground(pos: Vector2) -> void:
	global_position = pos
	is_stuck = true
	active = false
	if hit_area: hit_area.set_deferred("monitoring", false)
	get_tree().create_timer(stick_duration).timeout.connect(queue_free)

func _on_hit_something(_area):
	# Piercing logic: Do nothing, just deal damage
	pass
