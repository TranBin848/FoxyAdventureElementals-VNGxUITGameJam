extends BlackEmperorState

func _enter() -> void:
	obj.change_animation("idle")
	obj.velocity.x = 0
	timer = 0

func _update(_delta: float) -> void:
	#dont do anything until player is found
	if obj.found_player == null:
		return
		
	fsm.change_state(fsm.states.standup)
