extends WarLordState

var wait_time = 0.25

func _enter() -> void:
	obj.change_animation("shootLeft")
	timer = 0
	obj.is_facing_left = true
	shoot_and_rotate()

func _update(_delta: float) -> void:
	pass
	
func shoot_and_rotate() -> void:
	await get_tree().create_timer(wait_time).timeout
	for i in 2:
		obj.fire()
		await get_tree().create_timer(wait_time).timeout

	obj.change_animation("rotateL2R")
	await $"../../Direction/AnimatedSprite2D".animation_finished
	fsm.change_state(fsm.states.shootright)
