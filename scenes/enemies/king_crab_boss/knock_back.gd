extends KingCrabState

func _enter() -> void:
	obj.change_animation("knock back")
	timer = 0.4

func _update(_delta: float) -> void:
	if update_timer(_delta):
		fsm.change_state(fsm.states.stun)
