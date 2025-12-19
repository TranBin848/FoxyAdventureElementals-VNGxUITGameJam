extends PlayerState

func _enter() -> void:
	#Change animation to fall
	obj.change_animation("fall")
	pass

func _update(_delta: float) -> void:
	#Control moving
	var is_moving: bool = control_moving()
	
	control_dash()
	
	control_jump_attack()
	
	control_throw_blade()
	
	obj.is_right()
	
	if obj.is_on_wall() and is_moving and !obj.is_in_fireball_state:
		change_state(fsm.states.wallcling)
	
	#If on floor change to idle if not moving and not jumping
	if obj.is_on_floor() and not is_moving:
		change_state(fsm.states.idle)
	pass
