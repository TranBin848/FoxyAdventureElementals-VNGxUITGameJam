extends Debuff
@export var stunned_start_time: float = 1
@export var stunned_perform_time: float = 3
@export var stunned_end_time: float = 0.5

@export var turn_around_interval: Vector2 = Vector2(0.25, 0.5)

var turn_around_timer: float = 0

func _init_default_time_values() -> void:
	start_time = stunned_start_time
	perform_time = stunned_perform_time
	end_time = stunned_end_time

func start_state_enter() -> void:
	super.start_state_enter()
	if target != null: target.set_is_blind(true)
	turn_around_timer = randf_range(turn_around_interval.x, turn_around_interval.y)

func perform_state_update(delta: float) -> void:
	super.perform_state_update(delta)
	turn_around_timer -= delta
	if turn_around_timer <= 0:
		if target != null: target.turn_around()
		turn_around_timer = randf_range(turn_around_interval.x, turn_around_interval.y)

func end_state_exit() -> void:
	if target != null: target.set_is_blind(false)
	super.end_state_exit()
