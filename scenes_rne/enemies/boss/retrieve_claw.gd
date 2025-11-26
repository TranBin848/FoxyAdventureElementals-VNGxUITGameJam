extends KingCrabState

func _enter() -> void:
	obj.change_animation("retrieve claw")
	obj.velocity.x = 0
	await  $"../../Direction/AnimatedSprite2D".animation_finished
	change_state(fsm.states.stun)
