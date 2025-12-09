extends WarLordState

func _enter():
	obj.handle_dead()
	obj.change_animation("die")
	Engine.time_scale = 0.2
	await $"../../Direction/AnimatedSprite2D".animation_finished
	Engine.time_scale = 1.0
