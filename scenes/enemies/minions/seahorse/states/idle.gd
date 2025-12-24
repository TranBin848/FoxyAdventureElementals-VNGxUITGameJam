extends EnemyState

func _enter() -> void:
	obj.change_animation("idle")
	obj.velocity.x = 0

func _update(_delta: float) -> void:
	if obj.is_frozen: return
	if obj.found_player != null:
		var dir = obj.found_player.position - obj.position
		obj.change_direction(sign(dir.x))
		if obj.update_cool_down_timer(_delta): change_state(fsm.states.shoot)
	else: obj.update_cool_down_timer(_delta)
