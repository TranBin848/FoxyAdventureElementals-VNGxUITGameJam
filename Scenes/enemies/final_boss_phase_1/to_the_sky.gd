extends FinalPhaseOneState

func _enter() -> void:
	obj.change_animation("toTheSky")
	timer = 2

func _update(delta: float) -> void:
	
	#control_fly()
	
	if update_timer(delta):
		obj.spawn_mini_bosses()
		#print("TOI QUA MET")
		change_state(fsm.states.idle)

	print("BossPhase1 local position at 2t:", obj.position)
	print("BossPhase1 global position:", obj.global_position)
