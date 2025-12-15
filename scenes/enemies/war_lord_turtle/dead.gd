extends WarLordState

func _enter() -> void:
	AudioManager.play_sound("war_lord_defeat")
	obj.handle_dead()
	obj.change_animation("die")
