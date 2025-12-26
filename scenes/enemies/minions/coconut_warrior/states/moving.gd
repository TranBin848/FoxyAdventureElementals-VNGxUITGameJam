extends EnemyState

func _enter() -> void:
	obj.change_animation("moving")

func _update(_delta: float) -> void:
	if obj.is_frozen: return
	#Control moving
	control_moving()
	if obj.update_attack_timer(_delta):
		change_state(fsm.states.attack)
	
