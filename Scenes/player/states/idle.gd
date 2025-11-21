extends PlayerState

## Idle state for player character

func _enter() -> void:
	obj.change_animation("idle")

func _update(_delta: float) -> void:
	#Control jump
	control_jump()
	#Control moving
	control_moving()
	
	control_dash()
	
	control_attack()
	
	control_throw_blade()
	#If not on floor change to fall
	if not obj.is_on_floor():
		change_state(fsm.states.fall)
