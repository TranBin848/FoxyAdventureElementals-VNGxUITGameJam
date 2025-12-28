extends MarginContainer

@onready var video_player = $NinePatchRect/VideoStreamPlayer
@onready var close_button = $NinePatchRect/CloseTextureButton

func _ready():
	
	get_tree().paused = true
	close_button.pressed.connect(_on_close_texture_button_pressed)
	
func _exit_tree() -> void:
	get_tree().paused = false
	
func hide_popup():
	queue_free()
		
func _on_overlay_color_rect_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		hide_popup()

func _on_close_texture_button_pressed() -> void:
	hide_popup()
