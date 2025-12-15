extends EnemyState
#@export var detect_player_delay: float = 2.0

var ready_to_attack: bool = false

func _enter() -> void:
	obj.change_animation("idle")
	obj.velocity.x = 0
	#timer = detect_player_delay
	#ready_to_attack = false

func _update(_delta: float) -> void:
	ready_to_attack = obj.ready_to_turn_around()
	#if obj.found_player != null and ready_to_attack:
		#change_state(fsm.states.prepare)
	if obj.found_player != null:
		var direction: Vector2 = obj.found_player.position - obj.position
		if (sign(direction.x) == obj.direction):
			change_state(fsm.states.prepare)
		else:
			if ready_to_attack:
				change_state(fsm.states.prepare)
		
#func _update(_delta: float) -> void:
	#if obj.found_player != null:
		#var direction: Vector2 = obj.found_player.position - obj.position
		#if (sign(direction.x) == obj.direction):
			#change_state(fsm.states.prepare)
		#else:
			#if ready_to_attack and update_timer(_delta):
				#change_state(fsm.states.prepare)
			#elif not ready_to_attack:
				#ready_to_attack = true
				#timer = detect_player_delay
