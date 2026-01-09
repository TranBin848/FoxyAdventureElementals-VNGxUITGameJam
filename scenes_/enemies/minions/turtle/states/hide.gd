extends EnemyState

@export var hide_time: float = 3.0

func _enter() -> void:
	obj.change_animation("hide")
	obj.velocity.x = 0
	timer = hide_time
	obj.reset_moving_timer()

func _update(_delta: float) -> void:
	if obj.is_frozen: return
	#Control moving
	if update_timer(_delta): change_state(fsm.states.moving)
	super._update(_delta)

func take_damage(direction: Variant, damage: int = 1) -> void:
	pass
