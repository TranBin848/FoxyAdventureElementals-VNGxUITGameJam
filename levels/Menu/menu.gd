extends Control

@export var target_scene: PackedScene 

func _on_play_button_pressed() -> void:
	if target_scene:
		get_tree().change_scene_to_packed(target_scene)
	else:
		print("No scene assigned to target_scene!")

func _on_setting_button_pressed() -> void:
	var popup_settings = load("res://scenes/ui/settings_popup.tscn").instantiate()
	get_parent().add_child(popup_settings)

func _on_quit_button_pressed() -> void:
	get_tree().quit()
