extends Debuff
@export var weakness_start_time: float = 1
@export var weakness_perform_time: float = 5
@export var weakness_end_time: float = 0.5
@export var movement_speed_percentage: float = 0.5


func _init_default_time_values() -> void:
	start_time = weakness_start_time
	perform_time = weakness_perform_time
	end_time = weakness_end_time

func start_state_enter() -> void:
	super.start_state_enter()
	if target != null: 
		target.set_vulnerability(1)
		target.current_movement_speed = target.movement_speed * movement_speed_percentage

func perform_state_update(delta: float) -> void:
	super.perform_state_update(delta)

func end_state_exit() -> void:
	if target != null: 
		target.reset_vulnerability()
		target.current_movement_speed = target.movement_speed
	super.end_state_exit()
