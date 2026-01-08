extends MarginContainer

@onready var music_check_button: CheckButton = $BackgroundBoard/MarginContainer/SettingsList/MusicRow/MusicCheckButton
@onready var sfx_check_button: CheckButton = $BackgroundBoard/MarginContainer/SettingsList/SFXRow/SFXCheckButton
@onready var particle_slider: HSlider = $BackgroundBoard/MarginContainer/SettingsList/ParticlesGroup/SliderWraper/ParticleSlider

func _ready():
	# Load settings from SettingsManager
	music_check_button.button_pressed = SettingsManager.music_enabled
	sfx_check_button.button_pressed = SettingsManager.sfx_enabled
	particle_slider.value = SettingsManager.particle_quality
	
	get_tree().paused = true
	$BackgroundBoard/CloseTextureButton.pressed.connect(_on_close_texture_button_pressed)
	
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

func _on_unstuck_button_pressed() -> void:
	if GameManager.player:
		GameManager.player.unstuck()


func _on_menu_button_pressed() -> void:
	var warning_popup = load("res://scenes/ui/popup/menu_return_popup.tscn").instantiate()
	get_parent().add_child(warning_popup)
