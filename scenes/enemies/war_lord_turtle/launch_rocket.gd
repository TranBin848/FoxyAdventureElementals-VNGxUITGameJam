extends WarLordState

func _enter() -> void:
	obj.change_animation("rotate2Back")
	timer = 0
	obj.is_facing_left = true
	await $"../../Direction/AnimatedSprite2D".animation_finished
	obj.launch()

func exit() -> void:
	fsm.change_state(fsm.states.stun)
