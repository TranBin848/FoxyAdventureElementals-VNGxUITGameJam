extends Node2D

@export var life_time: float

func _physics_process(delta: float) -> void:
	if life_time > 0:
		life_time -= delta
	else:
		queue_free()
