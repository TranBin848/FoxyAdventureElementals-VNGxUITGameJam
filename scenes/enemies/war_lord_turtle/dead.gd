extends WarLordState

func _enter() -> void:
	AudioPlayer.play_sound_once(obj.defeated_sfx)
	obj.handle_dead()
	obj.change_animation("die")
