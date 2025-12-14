extends WarLordState

@export var stun_time: float = 5.0

func _enter() -> void:
	obj.change_animation("stun")
	timer = stun_time
	obj.is_attacking = false
	if obj.has_delay_state:
		obj.has_delay_state = false
		take_damage(0)

func _update(delta: float) -> void:
	super._update(delta)
	if update_timer(delta):
		change_state(fsm.states.idle)
	
