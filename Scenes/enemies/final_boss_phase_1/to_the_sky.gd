extends FinalPhaseOneState

func _enter() -> void:
	obj.change_animation("toTheSky")
	timer = 2
	obj.start_boss_fight()
	
func _update(delta: float) -> void:
	
	control_fly()
	
	if update_timer(delta):
		obj.spawn_mini_bosses()
		#print("TOI QUA MET")
		change_state(fsm.states.idle)
