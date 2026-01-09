extends EnemyState

func _enter() -> void:
	obj.change_animation("moving")

func _update(_delta: float) -> void:
	if obj.is_frozen: return
	#Control moving
	control_moving()
	
	if obj.found_player != null:
		change_state(fsm.states.prepare)
