extends KingCrabState

func _enter() -> void:
	obj.change_animation("fire claw")
	obj.velocity.x = 0
	await  $"../../Direction/AnimatedSprite2D".animation_finished
	obj.fire_claw()
	#timer = 2
#
#func _update(_delta: float) -> void:
	##Control moving
	#if update_timer(_delta):
		#change_state(fsm.states.stun)
	
