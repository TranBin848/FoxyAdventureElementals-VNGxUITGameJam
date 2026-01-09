extends EnemyState
@export var prepare_time: float = 0.4

func _enter() -> void:
	obj.change_animation("prepare")
	obj.velocity.x = 0
	timer = prepare_time

func _update(_delta: float) -> void:
	if obj.is_frozen: return
	if obj.found_player == null:
		change_state(fsm.states.idle)
	else:
		var direction: Vector2 = obj.found_player.position - obj.position
		if (sign(direction.x) != obj.direction):
			obj.turn_around()
		if (update_timer(_delta)):
			change_state(fsm.states.attack)
			
func _exit() -> void:
	obj.reset_turn_around_delay_timer()
