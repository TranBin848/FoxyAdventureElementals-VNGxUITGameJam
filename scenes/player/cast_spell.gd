extends PlayerState

func _enter() -> void:
	#Change animation to attack
	obj.change_animation("attack")
	timer = 0.2
	obj.velocity.x = 0

func _update(delta: float) -> void:
	#If attack is finished change to previous state
	if update_timer(delta):
		change_state(fsm.previous_state)
