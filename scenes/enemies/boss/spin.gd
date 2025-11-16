extends KingCrabState

func _enter() -> void:
	obj.change_animation("spin")
	timer = 2

func _update(_delta: float) -> void:
	#Control moving
	if update_timer(_delta):
		change_state(fsm.states.walk)
	
