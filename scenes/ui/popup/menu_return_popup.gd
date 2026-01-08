extends Control

func hide_popup():
	queue_free()

func _on_back_to_menu_pressed() -> void:
	get_tree().change_scene_to_file("res://levels/menu/menu.tscn")

func _on_close_button_pressed() -> void:
	hide_popup()
