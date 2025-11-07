class_name PelicanState
extends EnemyState

func control_moving() -> bool:
	obj.velocity.x = obj.movement_speed * obj.direction
	if _should_turn_around():
		obj.turn_around()
	return false
	
func control_flying_up() -> void:
	if obj._ground_check():
		obj.velocity.y = -obj.fly_force
		
func control_flying_away() -> void:
	obj.velocity.y = -obj.fly_force
	
func _update( _delta ):
	if obj.update_leave_timer(_delta):
		change_state(fsm.states.leave)
	pass
