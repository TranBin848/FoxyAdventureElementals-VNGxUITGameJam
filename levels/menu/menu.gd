extends Control

@export var target_scene: PackedScene 
const settings_popup: PackedScene = preload("res://scenes/ui/popup/settings_popup.tscn")

func _on_play_button_pressed() -> void:
	get_tree().change_scene_to_file("res://levels/menu/game_saves.tscn")

func _on_setting_button_pressed() -> void:
	var popup_settings = settings_popup.instantiate()
	get_parent().add_child(popup_settings)

func _on_quit_button_pressed() -> void:
	get_tree().quit()
