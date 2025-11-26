extends MarginContainer

@onready var music_check_button: CheckButton = $NinePatchRect/MusicCheckButton
@onready var sound_check_button: CheckButton = $NinePatchRect/SoundCheckButton

func _ready():
	sound_check_button.button_pressed = not AudioServer.is_bus_mute(AudioServer.get_bus_index("SFX"))
	music_check_button.button_pressed = not AudioServer.is_bus_mute(AudioServer.get_bus_index("Music"))
	get_tree().paused = true
	$NinePatchRect/CloseTextureButton.pressed.connect(_on_close_texture_button_pressed)
	
func _exit_tree() -> void:
	get_tree().paused = false

func _on_sound_check_button_toggled(toggled_on: bool) -> void:
	print("change sound")
	AudioServer.set_bus_mute(AudioServer.get_bus_index("SFX"), not toggled_on)

func _on_music_check_button_toggled(toggled_on: bool) -> void:
	print("change music")
	AudioServer.set_bus_mute(AudioServer.get_bus_index("Music"), not toggled_on)

func hide_popup():
	queue_free()
		
func _on_overlay_color_rect_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		hide_popup() # Replace with function body.

func _on_close_texture_button_pressed() -> void:
	hide_popup()
