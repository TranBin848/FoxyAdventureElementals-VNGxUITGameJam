extends WarLordState

var wait_time = 0.25
var animation_time = 0.6
var shoot_counter = 2
var phase = 0  # 0 = bắn, 1 = rotate

func _enter() -> void:
	obj.change_animation("shootLeft")
	obj.is_facing_left = true
	timer = wait_time
	shoot_counter = 2
	phase = 0


func _update(delta: float) -> void:
	if not update_timer(delta):
		return

	match phase:
		0:
			obj.fire()
			shoot_counter -= 1

			if shoot_counter > 0:
				timer = wait_time
			else:
				# Chuyển sang phase rotate
				phase = 1
				obj.change_animation("rotateL2R")
				timer = animation_time
		1:
			fsm.change_state(fsm.states.shootright)
