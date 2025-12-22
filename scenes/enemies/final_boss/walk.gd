extends BlackEmperorState

func _enter() -> void:
	obj.change_animation("moving")

func _update(_delta: float) -> void:
	#Control moving
	control_moving()
	if obj.found_player != null and obj.can_use_skill():
		var direction: Vector2 = obj.found_player.global_position - obj.global_position
		obj.change_direction(sign(direction.x))
		obj.use_skill()
