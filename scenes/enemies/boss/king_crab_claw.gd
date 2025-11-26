extends Node2D

@export var attack_sfx: AudioStream = null

var start_pos: Vector2 = Vector2.ZERO
var king_crab: KingCrab
var atk_range: float = 0
var speed = 0
var direction: float = 0

func _physics_process(delta: float) -> void:
	# Check camera edges
	var dist: float = global_position.x - start_pos.x
	#print(dist)
	#print("X: " + str(global_position.x) + ", Start: " + str(start_pos.x))
	scale.x = direction

	if abs(dist) > atk_range:
		if dist > 0:
			speed = -abs(speed)
		elif dist < 0:
			speed = abs(speed)
	# Move the object
	global_position.x += speed * delta

func is_at_camera_edge(margin: float = 15.0) -> bool:
	var cam := get_viewport().get_camera_2d()
	if cam == null:
		return false

	var viewport := get_viewport()
	var screen_size := viewport.get_visible_rect().size

	# Convert screen coords → world coords
	var canvas_xform := viewport.get_canvas_transform().affine_inverse()

	var left_edge  = canvas_xform * Vector2(0, screen_size.y * 0.5)
	var right_edge = canvas_xform * Vector2(screen_size.x, screen_size.y * 0.5)

	var x := global_position.x
	#print("camera edges:", left_edge, right_edge, " obj:", x)
	return (x <= left_edge.x + margin and speed < 0) or (x >= right_edge.x - margin and speed > 0) 


func _on_area_2d_body_entered(body: Node2D) -> void:
	if body is KingCrab:
		body.retrieve_claw()
	queue_free()
