extends WarLordState

@export var cd_skill: float = 1.5

func _enter() -> void:
	obj.change_animation("idle")
	timer = cd_skill
	obj.is_attacking = false

func _update(delta: float) -> void:
	super._update(delta)
	if update_timer(delta):
		handle_attack()
	
