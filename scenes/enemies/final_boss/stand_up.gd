extends BlackEmperorState

func _enter() -> void:
	obj.change_animation("idle")
	obj.velocity.x = 0
	timer = get_current_anim_duration()
	obj.start_boss_fight()
func _update(_delta: float) -> void:
	if update_timer(_delta):
		obj.use_skill()
	
