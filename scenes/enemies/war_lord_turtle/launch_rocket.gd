extends WarLordState

const ROTATE2BACK_TIME := 1.0
const LAUNCH_ROCKET_TIME := 0.6
const ROTATE2FRONT_TIME := 1.0

var phase := 0
var launch_times := 0
var launch_index := 0


func _enter() -> void:
	phase = 0
	launch_index = 0
	launch_times = obj.targets.size()

	obj.change_animation("rotate2Back")
	obj.is_facing_left = true
	timer = ROTATE2BACK_TIME


func _update(delta: float) -> void:
	match phase:
		0:
			_phase_rotate2back(delta)
		1:
			_phase_launch(delta)
		2:
			_phase_rotate2front(delta)
	#print(phase)

func _phase_rotate2back(delta: float) -> void:
	if update_timer(delta):
		phase = 1
		launch_index = 0
		timer = 0.1
		
func _phase_launch(delta: float) -> void:
	if launch_index >= launch_times:
		obj.change_animation("rotate2Front")
		timer = ROTATE2FRONT_TIME
		phase = 2
		return

	# chờ animation launchRocket
	if not update_timer(delta):
		return
		# reset animation về frame 0
	var anim = obj.get_animation_node()
	obj.change_animation("launchRocket")
	anim.frame = 0
	anim.play()
	
	timer = LAUNCH_ROCKET_TIME
	obj.launch(launch_index)
	obj.launch(launch_index+1)
	launch_index += 2

func _phase_rotate2front(delta: float) -> void:
	if update_timer(delta):
		fsm.change_state(fsm.states.stun)
