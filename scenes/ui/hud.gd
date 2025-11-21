extends MarginContainer

func _ready() -> void:
	$HBoxContainer/SettingsTextureButton.pressed.connect(_on_settings_texture_button_pressed)


func _on_settings_texture_button_pressed() -> void:
	var popup_settings = load("res://scenes/ui/settings_popup.tscn").instantiate()
	get_parent().add_child(popup_settings)
