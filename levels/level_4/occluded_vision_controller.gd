extends ColorRect

var player: Node2D

func _ready() -> void:
	call_deferred("_setup")


func _setup() -> void:
	if player == null:
		player = get_tree().get_first_node_in_group("player")

func _process(delta):
	if player:
		# Get the screen size
		var screen_size = get_viewport_rect().size
		
		# Get player position on screen (pixels)
		var player_screen_pos = player.get_global_transform_with_canvas().origin
		
		# CONVERT TO UV: Divide position by screen size to get 0.0 - 1.0 range
		var player_pos_normalized = player_screen_pos / screen_size
		
		# Calculate aspect ratio (Width / Height)
		var aspect_ratio = screen_size.x / screen_size.y
		
		# Send to shader
		material.set_shader_parameter("player_uv", player_pos_normalized)
		material.set_shader_parameter("ratio", aspect_ratio)
