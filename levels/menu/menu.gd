extends Control

@export var target_scene: PackedScene 
const settings_popup: PackedScene = preload("res://scenes/ui/popup/settings_popup.tscn")

func _on_play_button_pressed() -> void:
	GameManager.load_saved_game()

func _on_setting_button_pressed() -> void:
	var popup_settings = settings_popup.instantiate()
	get_parent().add_child(popup_settings)

func _on_quit_button_pressed() -> void:
	get_tree().quit()
