extends MarginContainer

@onready var music_slider: HSlider = $BackgroundBoard/MarginContainer/SettingsList/MusicRow/SliderWraper/MusicSlider
@onready var sfx_slider: HSlider = $BackgroundBoard/MarginContainer/SettingsList/SFXRow/SliderWraper/SFXSlider
@onready var particle_slider: HSlider = $BackgroundBoard/MarginContainer/SettingsList/ParticlesGroup/SliderWraper/ParticleSlider

# Optional: Labels to display current volume percentage
@onready var music_value_label: Label = $BackgroundBoard/MarginContainer/SettingsList/MusicRow/MusicValueLabel
@onready var sfx_value_label: Label = $BackgroundBoard/MarginContainer/SettingsList/SFXRow/SFXValueLabel

func _ready():
	# Configure Music Slider
	music_slider.min_value = 0
	music_slider.max_value = 100
	music_slider.step = 1
	music_slider.value = SettingsManager.music_volume
	music_slider.value_changed.connect(_on_music_slider_value_changed)
	
	# Configure SFX Slider
	sfx_slider.min_value = 0
	sfx_slider.max_value = 100
	sfx_slider.step = 1
	sfx_slider.value = SettingsManager.sfx_volume
	sfx_slider.value_changed.connect(_on_sfx_slider_value_changed)
	
	# Configure Particle Slider (unchanged)
	particle_slider.value = SettingsManager.particle_quality
	particle_slider.value_changed.connect(_on_particle_slider_value_changed)
	
	# Update value labels if they exist
	_update_volume_labels()
	
	get_tree().paused = true
	$BackgroundBoard/CloseTextureButton.pressed.connect(_on_close_texture_button_pressed)

func _exit_tree() -> void:
	get_tree().paused = false

func _on_music_slider_value_changed(value: float) -> void:
	SettingsManager.music_volume = int(value)
	_update_volume_labels()

func _on_sfx_slider_value_changed(value: float) -> void:
	SettingsManager.sfx_volume = int(value)
	_update_volume_labels()

func _on_particle_slider_value_changed(value: float) -> void:
	SettingsManager.particle_quality = int(value)

func _update_volume_labels() -> void:
	"""Updates the percentage labels next to sliders (if they exist)"""
	if music_value_label:
		music_value_label.text = str(SettingsManager.music_volume) + "%"
	
	if sfx_value_label:
		sfx_value_label.text = str(SettingsManager.sfx_volume) + "%"

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
