extends Node

@onready var camera2D: Camera2D = $Camera2D

var tween: Tween
var transitioning := false

# Variables to hold the state during transition
var transition_weight: float = 0.0
var start_pos: Vector2
var start_zoom: Vector2
var start_rot: float
var target_camera: Camera2D

func _ready():
	if camera2D == null:
		push_error("Camera2D node not found!")
		return
	# Disable processing initially to save performance
	set_process(false)

func _process(_delta):
	# If the target camera was deleted mid-transition, stop.
	if not is_instance_valid(target_camera):
		return

	# Interpolate Global Position
	# We lerp from the snapshot start_pos to the LIVE target_camera.global_position
	camera2D.global_position = start_pos.lerp(target_camera.global_position, transition_weight)
	
	# Interpolate Zoom
	camera2D.zoom = start_zoom.lerp(target_camera.zoom, transition_weight)
	
	# Interpolate Rotation
	camera2D.rotation = lerp_angle(start_rot, target_camera.rotation, transition_weight)

func transition_camera2D(to: Camera2D, duration := 1.0, from: Camera2D = get_viewport().get_camera_2d()) -> void:
	if transitioning:
		return
	
	# 1. Setup State
	target_camera = to
	start_pos = from.global_position
	start_zoom = from.zoom
	start_rot = from.rotation
	
	# Apply initial settings to our transition camera
	camera2D.zoom = start_zoom
	camera2D.offset = from.offset
	camera2D.light_mask = from.light_mask
	camera2D.global_position = start_pos
	camera2D.rotation = start_rot
	
	# Reset weight
	transition_weight = 0.0
	
	# 2. Start Transition
	camera2D.make_current()
	transitioning = true
	set_process(true) # Start the _process loop

	tween = create_tween()
	tween.set_parallel(true)
	tween.set_ease(Tween.EASE_IN_OUT)
	tween.set_trans(Tween.TRANS_CUBIC)

	# 3. Tween the WEIGHT, not the properties
	# This creates the curve (0.0 -> 1.0) that _process will use
	tween.tween_property(self, "transition_weight", 1.0, duration)

	await tween.finished

	# 4. Cleanup
	if is_instance_valid(to):
		to.make_current()
	
	transitioning = false
	set_process(false) # Stop the _process loop
