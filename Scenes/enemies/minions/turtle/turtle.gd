extends EnemyCharacter
@export var moving_time: float = 3.0
var moving_timer: float = 0

func _ready() -> void:
	super._ready()
	fsm = FSM.new(self, $States, $States/Moving)
	
func reset_moving_timer() -> void:
	moving_timer = moving_time

func update_moving_timer(_delta: float) -> bool:
	moving_timer -= _delta
	if moving_timer <= 0: return true
	return false
