extends PlayerState

func _enter() -> void:
	obj.change_animation("cling")
	pass

func _update(_delta: float):
	#Control moving
	var is_moving: bool = control_moving()
	
	#control wall jump
	control_wall_jump()
	
	if not obj.is_on_wall() or not is_moving:
		change_state(fsm.states.fall)
	pass
