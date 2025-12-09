extends WarLordState

func _enter() -> void:
	obj.change_animation("launchRocket")
	timer = 0
	obj.is_facing_left = true
	obj.launch()
	exit()

func exit() -> void:
	await $"../../Direction/AnimatedSprite2D".animation_finished
	fsm.change_state(fsm.states.stun)
