extends PlayerState

func _enter() -> void:
	#Change animation to jump
	obj.change_animation("jump")
	AudioPlayer.play_sound_once(obj.jump_sfx)
	pass

func _update(_delta: float):
	#Control moving
	control_moving()
	
	control_jump_attack()
	
	control_throw_blade()
	#If velocity.y is greater than 0 change to fall
	if obj.velocity.y > 0:
		change_state(fsm.states.fall)
	pass
