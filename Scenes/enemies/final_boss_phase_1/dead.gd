extends FinalPhaseOneState

@export var cd_skill: float = 3.0

func _enter() -> void:
	obj.change_animation("idle")
	timer = cd_skill
	obj.velocity.y = 0;
	if (not obj.mini_boss_is_not_ready()):
		obj.king_crab_instance.take_dame(obj.max_health)
		obj.war_lord_instance.take_dame(obj.max_health)
		

func _update(delta: float) -> void:
	super._update(delta)
	handle_mini_bosses()
	pass
