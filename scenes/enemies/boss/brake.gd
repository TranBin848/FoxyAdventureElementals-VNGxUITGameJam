extends KingCrabState

func _enter() -> void:
	obj.change_animation("brake")
	obj.velocity.x = obj.velocity.x/2

func _update(_delta: float) -> void:
	obj.velocity.x = lerp(obj.velocity.x, 0.0, 2.0 * _delta)
	if abs(obj.velocity.x) <= 5:
		obj.turn_around()
		change_state(fsm.states.walk)
	
