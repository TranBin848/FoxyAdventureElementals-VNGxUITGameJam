extends Node

@onready var camera2D: Camera2D = $Camera2D
var tween
var transitioning := false

func _ready():
	if camera2D == null:
		push_error("Camera2D node not found!")
		return
	

func transition_camera2D(to: Camera2D, duration := 1.0, from: Camera2D = get_viewport().get_camera_2d()) -> void:
	if transitioning:
		return
	
	# Copy initial camera values
	camera2D.zoom = from.zoom
	camera2D.offset = from.offset
	camera2D.light_mask = from.light_mask

	camera2D.global_position = from.global_position
	camera2D.rotation = from.rotation

	camera2D.make_current()
	transitioning = true

	tween = create_tween()
	tween.set_parallel(true)
	tween.set_ease(Tween.EASE_IN_OUT)
	tween.set_trans(Tween.TRANS_CUBIC)

	# Tween transform
	tween.tween_property(camera2D, "global_position", to.global_position, duration)
	tween.tween_property(camera2D, "rotation", to.rotation, duration)

	# Tween zoom (optional)
	tween.tween_property(camera2D, "zoom", to.zoom, duration)

	await tween.finished

	to.make_current()
	transitioning = false
