extends WarLordState

func _enter() -> void:
	obj.change_animation("inactive")
	timer = 0
	
func _update(_delta: float) -> void:
	print("is inactive")
	
	if obj.found_player != null:
		obj.change_animation("idle")
		#await $"../../Direction/AnimatedSprite2D".animation_finished
		change_state(fsm.states.idle)
		pass
	
