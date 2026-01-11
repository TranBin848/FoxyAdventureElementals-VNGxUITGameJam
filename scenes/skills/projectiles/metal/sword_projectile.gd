extends Node2D
class_name SwordProjectile

@export var fly_speed: float = 1500.0
@export var damage: int = 0
@export var elemental_type: ElementsEnum.Elements = ElementsEnum.Elements.NONE
@export var fade_duration: float = 10.0   # how long to fade before freeing

# Bezier Variables
var A: Vector2 
var B: Vector2 
var C: Vector2 
var curve_strength: float = 200.0 
var travel_time: float = 1.0

# Visuals
const ROTATION_OFFSET = 0 # Adjust if sword points wrong way (e.g. PI/2)
@onready var sprite: Sprite2D = $Sprite2D 
@onready var hit_area: HitArea2D = $HitArea2D
@onready var ground_ray: RayCast2D = $RayCast2D

var elapsed: float = 0.0
var active: bool = false
var is_stuck: bool = false
var stick_duration: float = 5.0
var sword_id := randi()

func setup_hover(pos: Vector2, dmg: int, elem: ElementsEnum.Elements, duration: float) -> void:
	damage = dmg
	elemental_type = elem
	stick_duration = duration
	global_position = pos
	active = false
	is_stuck = false
	
	# Randomize Sword Sprite
	if sprite:
		sprite.frame = randi() % (sprite.hframes * sprite.vframes)

	# Disable collider until launch
	if hit_area:
		hit_area.damage = damage
		hit_area.elemental_type = elemental_type
		hit_area.set_deferred("monitoring", false)
		if not hit_area.area_entered.is_connected(_on_hit_something):
			hit_area.area_entered.connect(_on_hit_something)

func launch(target: Vector2) -> void:
	A = global_position
	C = target
	
	# --- TRAJECTORY MATH ---
	var diff = C - A
	var dist = diff.length()
	var mid = A + (diff * 0.5)
	var perp = Vector2(diff.y, -diff.x).normalized()
	var max_width = min(curve_strength, dist * 0.5) 
	var random_width = randf_range(-max_width, max_width)
	B = mid + (perp * random_width)
	
	# Calculate Time
	var path_len = A.distance_to(B) + B.distance_to(C)
	travel_time = path_len / max(fly_speed, 100.0)
	
	# Initial Rotation
	var dir = (B - A).normalized() 
	rotation = dir.angle() + ROTATION_OFFSET
	
	elapsed = 0.0
	active = true
	if hit_area: 
		hit_area.set_deferred("monitoring", true)

func _physics_process(delta: float) -> void:
	if not active or is_stuck:
		return

	elapsed += delta
	var t := elapsed / travel_time

	var q0 := A.lerp(B, t)
	var q1 := B.lerp(C, t)
	var next_pos := q0.lerp(q1, t)

	if t > 1.0:
		var final_dir := (C - B).normalized()
		next_pos = global_position + final_dir * fly_speed * delta

	var motion := next_pos - global_position
	
	if motion.length() > 0.001:
		rotation = motion.angle() + ROTATION_OFFSET

	if ground_ray:
		var ray_length = max(32.0, motion.length() * 1.5)
		ground_ray.target_position = Vector2(ray_length, 0)
		ground_ray.force_raycast_update()

		if ground_ray.is_colliding():
			var hit_pos := ground_ray.get_collision_point()
			var normal := ground_ray.get_collision_normal().normalized()
			var dot := normal.dot(Vector2.UP)

			if dot > -0.1:
				_stick_to_ground(hit_pos, -normal)
				return
			else:
				print("Rejected surface (wall/steep slope)")

	global_position = next_pos

func _stick_to_ground(hit_pos: Vector2, embed_dir: Vector2) -> void:
	AudioManager.play_sound("skill_sword_hit_ground")
	set_as_top_level(true)
	global_position = hit_pos
	is_stuck = true
	active = false
	z_index = -1

	if hit_area:
		hit_area.set_deferred("monitoring", false)

	if ground_ray:
		ground_ray.enabled = false

	_start_fade_out()

func _start_fade_out() -> void:
	# Fade sprite AND trail
	var tween := create_tween()
	if sprite:
		tween.parallel().tween_property(sprite, "modulate:a", 0.0, fade_duration)
	
	tween.finished.connect(queue_free)

func _on_hit_something(_area):
	pass
