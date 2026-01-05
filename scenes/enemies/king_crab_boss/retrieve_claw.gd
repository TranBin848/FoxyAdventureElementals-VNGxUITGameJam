#extends KingCrabState
#
#func _enter() -> void:
	#obj.change_animation("retrieve claw")
	#obj.velocity.x = 0
	#await  $"../../Direction/AnimatedSprite2D".animation_finished
	#change_state(fsm.states.stun)

extends KingCrabState

func _enter() -> void:
	obj.change_animation("retrieve claw")
	obj.velocity.x = 0
	timer = get_current_anim_duration()
	print

func _update(_delta: float) -> void:
	if update_timer(_delta):
		change_state(fsm.states.stun)
