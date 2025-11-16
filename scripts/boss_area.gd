extends Area2D
@onready var camera_2d: Camera2D = $Camera2D


func _on_body_entered(body: Node2D) -> void:
	CameraTransition.transition_camera2D(camera_2d)
