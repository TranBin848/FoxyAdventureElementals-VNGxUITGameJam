extends AreaBase
class_name ThunderboltArea

@export var knockback_force: float = 350.0

func setup(skill: Skill, caster_position: Vector2, enemy: EnemyCharacter, _direction: Vector2 = Vector2.ZERO) -> void:
	super.setup(skill, caster_position, enemy)
	
	# Immediately disable enemy movement
	if targetenemy and is_instance_valid(targetenemy):
		targetenemy.enter_stun(global_position)
		
	AudioManager.play_sound("skill_thunderbolt_crackle")

# Called by AnimationPlayer method track when startup animation completes
func _on_startup_complete() -> void:
	_enable_hitbox()  # Enable damage detection

# Called by AnimationPlayer method track at knockback frame
func _apply_stun_effect() -> void:
	AudioManager.play_sound("skill_thunderbolt")
	if targetenemy and is_instance_valid(targetenemy):
		targetenemy.exit_skill()
	_disable_hitbox()
