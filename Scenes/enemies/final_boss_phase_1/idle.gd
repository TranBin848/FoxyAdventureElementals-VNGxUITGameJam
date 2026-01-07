extends FinalPhaseOneState

func _enter() -> void:
	obj.change_animation("idle")
	obj.velocity.y = 0;

func _update(delta: float) -> void:
	super._update(delta)
	handle_mini_bosses()
	print(obj.health)
	pass
