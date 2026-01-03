extends FinalPhaseOneState

func _enter() -> void:
	obj.change_animation("inactive")
	timer = 1.5


func _update(delta: float) -> void:
	if obj.is_fighting == false:
		return
	if update_timer(delta):
		obj.start_fight()
		change_state(fsm.states.tothesky)
