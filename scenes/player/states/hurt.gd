extends PlayerState


func _enter():
	obj.change_animation("hurt")
	AudioManager.play_sound("player_hurt")
	obj.velocity.y = -250
	timer = 0.5


func _update( delta: float):
	if update_timer(delta):
		change_state(fsm.states.idle)
		obj.set_invulnerable()
