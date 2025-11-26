extends KingCrabState

func _enter() -> void:
	obj.change_animation("inactive")
	obj.velocity.x = 0
	timer = 0

func _update(_delta: float) -> void:
	if obj.found_player != null:
		obj.change_animation("stand up")
		await $"../../Direction/AnimatedSprite2D".animation_finished
		fsm.change_state(fsm.states.walk)
		pass
	
