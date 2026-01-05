extends FinalPhaseOneState

func _enter() -> void:
	obj.change_animation("hurt")
	timer = 0.5


func _update(delta: float) -> void:
	if update_timer(delta):
		change_state(fsm.previous_state)
	super._update(delta)
