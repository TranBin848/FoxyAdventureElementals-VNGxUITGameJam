extends PlayerState

var aim_timer: float = 0.2

func _enter() -> void:
	#Change animation to attack
	obj.change_animation("attack")
	timer = 0.15
	obj.velocity.x = 0


func _update(delta: float) -> void:
	#If attack is finished change to previous state
	if update_timer(delta):
		obj.throw_blade()
		change_state(fsm.previous_state)
