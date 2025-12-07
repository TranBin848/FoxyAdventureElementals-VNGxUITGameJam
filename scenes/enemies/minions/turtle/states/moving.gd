extends EnemyState

func _enter() -> void:
	obj.change_animation("moving")

func _update(_delta: float) -> void:
	#Control moving
	control_moving()
	if obj.update_moving_timer(_delta):
		change_state(fsm.states.hide)
	
