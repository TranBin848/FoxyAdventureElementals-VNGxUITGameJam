extends AreaBase
class_name WaterSpikeArea

@export var knockback_force: float = 350.0

func setup(skill: Skill, caster_position: Vector2, enemy: EnemyCharacter, _direction: Vector2 = Vector2.RIGHT) -> void:
	super.setup(skill, caster_position, enemy, _direction)
	
	# Use scaled damage
	self.damage = skill.get_scaled_damage()
	
	if targetenemy and is_instance_valid(targetenemy):
		targetenemy.enter_stun(global_position)

func _ready() -> void:
	AudioManager.play_sound("skill_water_spike")

func _apply_knockback_effect() -> void:
	if targetenemy and is_instance_valid(targetenemy):
		targetenemy.exit_skill()
		
		var knockback_vector = Vector2(
			direction.x * knockback_force * 0.5,
			-knockback_force
		)
		
		targetenemy.apply_knockback(knockback_vector)

func _on_startup_complete() -> void:
	_enable_hitbox()
	if targetenemy and is_instance_valid(targetenemy):
		targetenemy.enter_tornado(global_position)