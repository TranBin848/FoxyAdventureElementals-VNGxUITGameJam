extends EnemyState

@export var hurt_time: float = 0.5
@export var hurt_bounce_velocity: float = 200

func _enter() -> void:
	obj.change_animation("hurt")
	timer = hurt_time
	# Stop horizontal movement for barrel - it shouldn't move when hit
	obj.velocity.x = 0
	
func _update(_delta):
	# Keep horizontal velocity at 0 to prevent barrel from moving
	obj.velocity.x = 0
	
	if update_timer(_delta):
		change_state(fsm.previous_state)
