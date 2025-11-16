class_name KingCrabState
extends EnemyState

func control_moving() -> bool:
	obj.velocity.x = obj.movement_speed * obj.direction
	if _should_turn_around():
		obj.turn_around()
	return false

func _should_turn_around() -> bool:
	if (obj.is_touch_wall() or obj.is_can_fall()) and obj.is_on_floor(): return true
	return false
	
func _update( _delta ):
	if obj.update_leave_timer(_delta):
		change_state(fsm.states.leave)
	pass
