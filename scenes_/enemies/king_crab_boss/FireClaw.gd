extends KingCrabState

func _enter() -> void:
	obj.change_animation("fire claw")
	obj.velocity.x = 0
	#await  $"../../Direction/AnimatedSprite2D".animation_finished
	timer = 0.2
	
#
func _update(_delta: float) -> void:
	#Control moving
	if update_timer(_delta):
		obj.fire_claw()

func _exit() ->void:
	if obj.fired_claw:
		obj.fired_claw.queue_free()
