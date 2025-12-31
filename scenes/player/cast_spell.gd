extends PlayerState

func _enter() -> void:
	#Change animation to attack
	obj.change_animation("attack")
	timer = 0.5
	obj.velocity.x = 0

func _update(delta: float) -> void:
	#Control jump
	control_jump()
	#Control moving
	control_moving()
	
	control_dash()
	
	control_attack()
	
	#If attack is finished change to previous state
	if update_timer(delta):
		change_state(fsm.previous_state)
