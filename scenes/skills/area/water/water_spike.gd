extends AreaBase
class_name WaterSpikeArea

@export var knockback_force: float = 350.0

func setup(skill: Skill, caster_position: Vector2, enemy: EnemyCharacter, _direction: Vector2 = Vector2.RIGHT) -> void:
	super.setup(skill, caster_position, enemy, _direction)
	self.damage = damage * (skill.level + 1) * 0.5
	
	if targetenemy and is_instance_valid(targetenemy):
		targetenemy.enter_stun(global_position)

func _apply_knockback_effect() -> void:
	if targetenemy and is_instance_valid(targetenemy):
		targetenemy.exit_skill()
		
		# Use stored casting_direction from parent
		var knockback_vector = Vector2(
			direction.x * knockback_force * 0.5,
			-knockback_force  # Upward launch
		)
		
		targetenemy.apply_knockback(knockback_vector)

# Called by AnimationPlayer method track when startup animation completes
func _on_startup_complete() -> void:
	_enable_hitbox()  # Enable damage detection
		# Immediately disable enemy movement
	if targetenemy and is_instance_valid(targetenemy):
		targetenemy.enter_tornado(global_position)
