extends PlayerState


func _enter():
	obj.change_animation("hurt")
	AudioPlayer.play_sound_once(obj.hurt_sfx)
	obj.velocity.y = -250
	timer = 0.5


func _update( delta: float):
	if update_timer(delta):
		change_state(fsm.states.idle)
		obj.set_invulnerable()
