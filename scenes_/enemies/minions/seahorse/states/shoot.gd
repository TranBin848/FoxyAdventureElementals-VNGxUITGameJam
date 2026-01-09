extends EnemyState
@export var shoot_start_time: float = 1.8
@export var shoor_end_time: float = 0.1

func _enter() -> void:
	timer = shoot_start_time
	obj.change_animation("shoot")
	pass

func _update( _delta ):
	if obj.is_frozen: return
	if (update_timer((_delta))):
		#print(obj.ball_counter)
		if obj.ball_counter == obj.ball_count:
			obj.ball_counter = 0
			obj.start_cool_down()
			change_state(fsm.states.idle)
			return
		obj.shoot()
		if obj.ball_counter == obj.ball_count:
			timer = shoor_end_time
		else: timer = shoot_start_time + shoor_end_time
	
