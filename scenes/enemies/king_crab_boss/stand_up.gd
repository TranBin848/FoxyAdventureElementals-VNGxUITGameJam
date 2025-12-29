extends KingCrabState

func _enter() -> void:
	obj.change_animation("stand up")
	obj.velocity.x = 0
	timer = get_current_anim_duration()

func _update(_delta: float) -> void:
	if update_timer(_delta):
		fsm.change_state(fsm.states.walk)

func _exit() -> void:
	if obj.is_phase_changed():
		obj.change_phase()
