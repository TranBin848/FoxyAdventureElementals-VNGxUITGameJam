class_name PelicanState
extends EnemyState

func control_moving() -> bool:
	obj.velocity.x = obj.current_movement_speed * obj.direction
	#print(_should_turn_around())
	if _should_turn_around():
		obj.turn_around()
	return false

func _should_turn_around() -> bool:
	if (obj.is_touch_wall() or obj.is_can_fall()): return true
	return false

func control_flying_up() -> void:
	if obj._ground_check():
		obj.velocity.y = -obj.current_fly_force
		
func control_flying_away() -> void:
	obj.velocity.y = -obj.current_fly_force
	
func _update( _delta ):
	#if obj.update_leave_timer(_delta):
		#change_state(fsm.states.leave)
	pass
