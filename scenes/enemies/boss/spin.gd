extends KingCrabState

func _enter() -> void:
	obj.change_animation("spin")
	timer = 2

func _update(_delta: float) -> void:
	#Control moving
	#if update_timer(_delta):
		#change_state(fsm.states.walk)
		
	if obj.is_at_camera_edge(100):
		change_state(fsm.states.brake)
		pass
	
