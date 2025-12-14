extends WarLordState

var activated := false

func _enter() -> void:
	obj.change_animation("inactive")
	obj.elemental_type = obj.phase_order[obj.current_phase_index]
	obj.apply_element()
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
