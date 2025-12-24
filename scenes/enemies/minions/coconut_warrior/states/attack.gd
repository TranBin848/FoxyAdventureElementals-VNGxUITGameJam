extends EnemyState
@export var throw_start_time: float = 0.4
@export var attack_time: float = 0.8
var throw_timer: float = 0
var has_thrown: bool = false

func _enter() -> void:
	timer = attack_time
	throw_timer = throw_start_time
	obj.change_animation("attack")
	has_thrown = false

func _update(_delta):
	if obj.is_frozen: return
	control_moving()
	
	# Check if attack duration is complete
	if update_timer(_delta):
		change_state(fsm.states.moving)
		return
	
	# Execute throw at the correct timing
	if update_throw_timer(_delta) and not has_thrown:
		obj.throw()
		has_thrown = true
		obj.reset_attack_timer()

func update_throw_timer(delta: float) -> bool:
	throw_timer -= delta
	if throw_timer <= 0: 
		return true
	return false
