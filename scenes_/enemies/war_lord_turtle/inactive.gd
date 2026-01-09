extends WarLordState

var activated := false

func _enter() -> void:
	obj.change_animation("inactive")
	activated = false


func _update(delta: float) -> void:
	if obj.is_fighting == false:
		return
	if not activated:
		activated = true
		timer = 1.5
		obj.change_animation("standUp")
		$"../../GPUParticles2D".show()
		$"../../Particles".hide()
		return
	if update_timer(delta):
		$"../../GPUParticles2D".hide()
		$"../../Particles".show()
		obj.start_fight()
		change_state(fsm.states.idle)

func _exit() -> void:
	obj.update_phase_index()
	obj.change_phase()
