extends WarLordState

@export var cd_skill: float = 3.0
var action_timer: float = 0.0


func _enter() -> void:
	obj.change_animation("idle")
	action_timer = cd_skill


func _update(delta: float) -> void:
	super._update(delta)
	if action_timer > 0:
		action_timer -= delta
		if action_timer <= 0:
			handle_attack()
