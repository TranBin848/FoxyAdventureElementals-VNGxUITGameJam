extends EnemyState

# Used to change starfish speed when it stops rolling
var start_speed: float
# Roll speed ratio compared to movement speed
var roll_speed_ratio: float = 1.5

func _enter() -> void:
	obj.velocity.x = 0
	obj.change_animation("roll")
	start_speed = obj.movement_speed
	obj.movement_speed = obj.movement_speed * roll_speed_ratio
	timer = obj.roll_time
	pass

func _exit() -> void:
	#if obj.detected_player_icon != null:
		#obj.detected_player_icon.visible = false
	obj.movement_speed = start_speed
	pass

func _update( _delta ):	
	control_moving()
	if update_timer(_delta):
		change_state(fsm.states.moving)
	#if obj.found_player == null:
		#change_state(fsm.states.moving)
	pass

func control_moving() -> bool:
	if obj.is_on_floor():
		obj.velocity.x = obj.movement_speed * obj.direction
	if _should_turn_around():
		obj.turn_around()
		change_state(fsm.states.moving)
	return false

#func _on_hit_area_2d_area_entered(area: Area2D):
	#change_state(fsm.states.prepare)
