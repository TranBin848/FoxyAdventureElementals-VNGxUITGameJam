extends EnemyState

@export var spawn_start_time: float = 0.6
@export var spawn_end_time: float = 0.6

var has_spawned: bool = false

func _enter() -> void:
	obj.change_animation("spawn")
	has_spawned = false
	timer = spawn_start_time

func _update(_delta: float) -> void:
	if (update_timer(_delta)):
		if has_spawned:
			fsm.change_state(fsm.states.idle)
		else:
			timer = spawn_end_time
			if (not obj.spawn_enemy()): fsm.change_state(fsm.states.dead)
			has_spawned = true
