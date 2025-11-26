extends PelicanState

func _enter() -> void:
	obj.change_animation("moving")
	timer = obj.drop_bomb_interval

func _update(_delta: float) -> void:
	#Control moving
	control_moving()
	control_flying_up()
	if update_timer(_delta): change_state(fsm.states.drop_bomb)
	super._update(_delta)
