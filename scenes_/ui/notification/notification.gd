extends Node2D

@export var on_screen_offset: Vector2 = Vector2(0, -40)
@export var screen_margin: float = 50.0
@export var smoothing_speed: float = 20.0 # Increased for snappier edge movement
@export var max_detection_distance: float = 500.0
@export var fade_distance: float = 50.0 

# NOTE: This assumes your icon sprite points UP by default. 
# If it points RIGHT, change this to 0.0.
@export var rotation_offset_degrees: float = 90.0 

@onready var icon: Sprite2D = $OnScreenIcon

var player_node: Node2D 
var camera_node: Camera2D
var target_display_position: Vector2
var target_display_rotation: float
var is_on_screen: bool = true

func _process(delta):
	if player_node == null:
		player_node = get_tree().get_first_node_in_group("player")
		return
	
	if camera_node == null:
		camera_node = get_viewport().get_camera_2d()
		return
	
	var target_global_pos = get_parent().global_position
	var distance_squared = player_node.global_position.distance_squared_to(target_global_pos)
	var max_distance_squared = max_detection_distance * max_detection_distance
	var fade_distance_squared = fade_distance * fade_distance
	var fade_threshold_squared = max_distance_squared - fade_distance_squared
	
	# 1. Distance Check & Fading
	if distance_squared > max_distance_squared:
		visible = false
		return
	
	visible = true
	
	if distance_squared > fade_threshold_squared:
		var fade_ratio = (distance_squared - fade_threshold_squared) / fade_distance_squared
		modulate.a = clamp(1.0 - fade_ratio, 0.0, 1.0)
	else:
		modulate.a = 1.0
	
	# 2. Screen Calculation
	var viewport_dims = get_viewport_rect().size
	var screen_coords = (target_global_pos - camera_node.global_position) * camera_node.zoom
	screen_coords += viewport_dims / 2
	var screen_rect = Rect2(Vector2.ZERO, viewport_dims).grow(-screen_margin)

	if screen_rect.has_point(screen_coords):
		# --- ON SCREEN ---
		is_on_screen = true
		
		# Position: Global position of parent + offset
		target_display_position = target_global_pos + on_screen_offset
		
		# Rotation: Reset to 0 (Upright)
		target_display_rotation = 0.0
		
	else:
		# --- OFF SCREEN ---
		is_on_screen = false
		
		# Position: Clamp to screen edges
		var clamped_x = clamp(screen_coords.x, screen_margin, viewport_dims.x - screen_margin)
		var clamped_y = clamp(screen_coords.y, screen_margin, viewport_dims.y - screen_margin)
		var clamped_coords = Vector2(clamped_x, clamped_y)

		# Convert screen space back to global world space for the Node2D
		target_display_position = camera_node.global_position + (clamped_coords - viewport_dims / 2) / camera_node.zoom

# 3. Apply Movement
	if is_on_screen:
		# Floating behavior: Smooth movement when following the unit
		global_position = global_position.lerp(target_display_position, smoothing_speed * delta)
	else:
		# HUD behavior: Snap INSTANTLY to the edge so camera movement doesn't detach it
		global_position = target_display_position
	
	# Rotation can always be smooth
	rotation = lerp_angle(rotation, target_display_rotation, smoothing_speed * delta)
