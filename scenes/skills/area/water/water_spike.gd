extends AreaBase
class_name WaterSpikeArea

@export var knockback_force: float = 350.0

func setup(skill: Skill, caster_position: Vector2, enemy: EnemyCharacter) -> void:
	super.setup(skill, caster_position, enemy)
	
	# Immediately disable enemy movement
	if targetenemy and is_instance_valid(targetenemy):
		targetenemy.enter_skill(global_position)

# Called by AnimationPlayer method track when startup animation completes
func _on_startup_complete() -> void:
	_enable_hitbox()  # Enable damage detection

# Called by AnimationPlayer method track at knockback frame
func _apply_knockback_effect() -> void:
	if targetenemy and is_instance_valid(targetenemy):
		targetenemy.exit_skill()
		targetenemy.apply_knockback(self.global_position, knockback_force)
