extends FinalPhaseOneState

@export var left_speed = -600

func _enter() -> void:
	obj.change_animation("dead")
	timer = 0.5
	kill_minibosses()
		

func _update(delta: float) -> void:
	super._update(delta)
	handle_mini_bosses()
	if update_timer(delta):
		obj.handle_dead()
	pass
