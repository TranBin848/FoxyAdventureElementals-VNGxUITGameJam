extends WarLordState

var wait_time = 1.2

func _enter() -> void:
	obj.change_animation("launchRocket")
	timer = 0
	obj.is_facing_left = true
	obj.launch()
	exit()

func exit() -> void:
	await get_tree().create_timer(wait_time).timeout
	fsm.change_state(fsm.states.idle)
