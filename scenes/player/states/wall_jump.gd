extends PlayerState

func _enter() -> void:
	#Change animation to jump
	obj.change_animation("jump")
	AudioPlayer.play_sound_once(obj.jump_sfx)
	timer = 0.3
	obj.velocity.x = obj.movement_speed * obj.direction


func _update(_delta: float):
	#Control moving
	#player is not allowed to perform action at the 
	#start of wall jump
	if update_timer(_delta):
		change_state(fsm.states.jump)
	
	control_dash()
	
	#If velocity.y is greater than 0 change to fall
	if obj.velocity.y > 0:
		change_state(fsm.states.fall)
	pass
