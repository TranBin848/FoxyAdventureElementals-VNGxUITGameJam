extends MarginContainer

@onready var music_check_button: CheckButton = $NinePatchRect/MusicCheckButton
@onready var sfx_check_button: CheckButton = $NinePatchRect/SFXCheckButton
@onready var particle_slider: HSlider = $NinePatchRect/ParticleSlider

func _ready():
	# Load settings from SettingsManager
	music_check_button.button_pressed = SettingsManager.music_enabled
	sfx_check_button.button_pressed = SettingsManager.sfx_enabled
	particle_slider.value = SettingsManager.particle_quality
	
	get_tree().paused = true
	$NinePatchRect/CloseTextureButton.pressed.connect(_on_close_texture_button_pressed)
	
func _exit_tree() -> void:
	get_tree().paused = false

func _on_sound_check_button_toggled(toggled_on: bool) -> void:
	SettingsManager.sfx_enabled = toggled_on

func _on_music_check_button_toggled(toggled_on: bool) -> void:
	SettingsManager.music_enabled = toggled_on
	
func _on_particle_slider_value_changed(value: float) -> void:
	SettingsManager.particle_quality = int(value)

func hide_popup():
	queue_free()
		
func _on_overlay_color_rect_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		hide_popup()

func _on_close_texture_button_pressed() -> void:
	hide_popup()
