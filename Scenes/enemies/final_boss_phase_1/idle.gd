extends FinalPhaseOneState

@export var cd_skill: float = 3.0

func _enter() -> void:
	obj.change_animation("idle")
	timer = cd_skill
	obj.velocity.y = 0;

func _update(delta: float) -> void:
	#super._update(delta)
	#if update_timer(delta):
		#handle_attack()
		
	print("BossPhase1 local position idle:", obj.position)
	print("BossPhase1 global position:", obj.global_position)
	pass
