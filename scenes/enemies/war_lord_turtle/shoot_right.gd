extends WarLordState

var wait_time = 0.25

func _enter() -> void:
	obj.change_animation("shootRight")
	timer = 0
	obj.is_facing_left = false
	shoot_and_rotate()

func _update(_delta: float) -> void:
	pass
	
func shoot_and_rotate() -> void:
	await get_tree().create_timer(wait_time).timeout
	for i in 2:
		obj.fire()
		await get_tree().create_timer(wait_time).timeout

	# Quay rồi đổi state
	obj.change_animation("rotateR2L")
	await $"../../Direction/AnimatedSprite2D".animation_finished
	fsm.change_state(fsm.states.stun)
