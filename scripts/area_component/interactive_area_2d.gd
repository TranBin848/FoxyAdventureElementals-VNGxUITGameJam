class_name InteractiveArea2D
extends Area2D

#signal when player interact with the area
signal interacted

#signal when player can interact with the area
signal interaction_available

#signal when player can't interact with the area
signal interaction_unavailable

@export var interact_input_action = "interact"


func _ready():
	set_process_unhandled_input(false)
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)


func _unhandled_input(event):
	if event.is_action_pressed(interact_input_action):
		interacted.emit()
		var viewport = get_viewport()
		if viewport != null:
			viewport.set_input_as_handled()

func _on_body_entered(_body: Node2D) -> void:
	set_process_unhandled_input(true)
	interaction_available.emit()


func _on_body_exited(_body: Node2D) -> void:
	set_process_unhandled_input(false)
	interaction_unavailable.emit()
