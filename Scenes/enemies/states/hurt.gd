extends EnemyState

@export var hurt_time: float = 0.5
@export var hurt_bounce_velocity: float = 200

func _enter() -> void:
	obj.change_animation("hurt")
	obj.velocity.y = -hurt_bounce_velocity
	timer = hurt_time
	
func _update( _delta ):
	if update_timer(_delta):
		change_state(fsm.previous_state)
