extends WarLordState

@export var stun_time: float = 5.0
var action_timer: float = 0.0

func _enter() -> void:
	obj.change_animation("stun")
	timer = 0
	action_timer = stun_time

func _update(delta: float) -> void:
	super._update(delta)
	if action_timer > 0:
		action_timer -= delta
		if action_timer <= 0:
			change_state(fsm.states.idle)
	
