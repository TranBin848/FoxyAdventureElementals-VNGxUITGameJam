extends EnemyState

func _enter() -> void:
	obj.change_animation("idle")

func _update(_delta: float) -> void:
	if obj.update_spawn_timer(_delta) && obj.found_player != null:
		change_state(fsm.states.spawn)
