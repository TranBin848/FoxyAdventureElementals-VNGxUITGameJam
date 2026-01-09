extends PelicanState

@export var total_bomb: int = 1
@export var drop_bomb_start_time: float = 0.3
@export var drop_bomb_end_time: float = 0.2

var drop_bomb_timer: float = 0
var bomb_count: int

func _enter() -> void:
	obj.change_animation("drop_bomb")
	bomb_count = total_bomb
	drop_bomb_timer = drop_bomb_start_time

func _update(_delta: float) -> void:
	if obj.is_frozen: return
	#Control moving
	control_moving()
	control_flying_up()
	control_drop_bomb(_delta)
	super._update(_delta)

func control_drop_bomb(_delta: float) -> void:
	drop_bomb_timer -= _delta
	if drop_bomb_timer <= 0:
		if bomb_count <= 0:
			change_state(fsm.states.moving)
			return
		
		drop_bomb()
		if bomb_count > 0:
			drop_bomb_timer = drop_bomb_end_time + drop_bomb_start_time
		else: drop_bomb_timer = drop_bomb_end_time
	pass

func drop_bomb() -> void:
	obj.drop_bomb()
	bomb_count -= 1
	pass
