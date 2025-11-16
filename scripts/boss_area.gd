extends Area2D
@onready var camera_2d: Camera2D = $Camera2D
@onready var boss: CharacterBody2D = $Boss


func _on_body_entered(body: Node2D) -> void:
	CameraTransition.transition_camera2D(camera_2d, 2)
	#boss.fsm.chan
