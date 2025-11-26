extends EnemyState
@export var prepare_time: float = 0.25

func _enter() -> void:
	obj.velocity.x = 0
	obj.change_animation("prepare")
	if obj.detected_player_icon != null:
		obj.detected_player_icon.visible = true
	timer = prepare_time
	pass

func _exit() -> void:
	if obj.detected_player_icon != null:
		obj.detected_player_icon.visible = false
	pass

func _update( _delta ):
	if obj.found_player == null:
		change_state(fsm.states.moving)
		return
	
	var direction: Vector2 = obj.found_player.position - obj.position
	print(obj.found_player.position)
	print(obj.position)
	obj.change_direction(sign(direction.x))
	
	if update_timer(_delta):
		change_state(fsm.states.roll)
	pass
