class_name TurtleState
extends EnemyState

func _update( _delta ):
	if obj.is_frozen: return
	obj.update_moving_timer(_delta)
	pass
