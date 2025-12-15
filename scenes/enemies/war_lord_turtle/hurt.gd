extends WarLordState

func _enter():
	obj.change_animation("hurt")
	timer = 0.2

func _update( delta: float):
	if update_timer(delta):
		if obj.health <= 0:
			change_state(fsm.states.dead)
		else:
			obj.phase_check()
			change_state(fsm.states.idle)
