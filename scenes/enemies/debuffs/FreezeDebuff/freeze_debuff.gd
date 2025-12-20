extends Debuff
@export var freeze_start_time: float = 1.7
@export var freeze_perform_time: float = 2
@export var freeze_end_time: float = 1.6


func _init_default_time_values() -> void:
	start_time = freeze_start_time
	perform_time = freeze_perform_time
	end_time = freeze_end_time

func start_state_enter() -> void:
	super.start_state_enter()
	if target != null: target.freeze_in_place(true)

func perform_state_update(delta: float) -> void:
	super.perform_state_update(delta)
	if target != null: target.velocity.x = 0

func end_state_exit() -> void:
	if target != null: target.freeze_in_place(false)
	super.end_state_exit()
