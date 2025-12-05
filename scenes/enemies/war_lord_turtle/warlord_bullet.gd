class_name WarLordBullet
extends RigidBody2D

@export var gravity := 980.0
@export var angle := -45.0

func fire(start_pos: Vector2, target_pos: Vector2, angle_deg: float, dir: float):
	position = start_pos
	var v = compute_initial_velocity(start_pos, target_pos, angle_deg, gravity) * dir
	linear_velocity = v


func compute_initial_velocity(p0: Vector2, p1: Vector2, angle_deg: float, g: float) -> Vector2:
	var theta = deg_to_rad(angle_deg)
	var dx = p1.x - p0.x
	var dy = p1.y - p0.y
	
	if abs(dx) < 1e-6:
		return Vector2.ZERO

	var cos_t = cos(theta)
	var sin_t = sin(theta)

	var denom = 2 * cos_t * cos_t * (dx * tan(theta) - dy)
	if denom <= 0:
		print("Impossible shot with this angle")
		return Vector2.ZERO

	var v = sqrt(g * dx * dx / denom)
	return Vector2(v * cos_t, v * sin_t)


func _on_hit_area_2d_hitted(_area: Variant) -> void:
	queue_free()

func _on_body_entered(_body: Node) -> void:
	queue_free()
