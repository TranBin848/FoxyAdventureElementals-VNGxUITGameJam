extends KingCrabState

func _enter() -> void:
	obj.change_animation("stun")
	obj.velocity.x = 0
	timer = 2

func _update(_delta: float) -> void:
	if update_timer(_delta):
		fsm.change_state(fsm.states.standup)

	
