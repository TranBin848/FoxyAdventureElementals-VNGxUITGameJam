extends KingCrabState

func _enter() -> void:
	obj.change_animation("spin")
	timer = 2
	obj.velocity.x = abs(obj.velocity.x)*sign(obj.direction)

func _update(_delta: float) -> void:
	print("direction: " + str(obj.direction) + " velocity x: " + 
	str(obj.velocity.x))
	if obj.is_at_camera_edge(100):
		change_state(fsm.states.brake)
		pass
	
