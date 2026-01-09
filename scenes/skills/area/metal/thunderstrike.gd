extends AreaBase
class_name ThunderStrikeArea

@export var knockback_force: float = 350.0

func setup(skill: Skill, caster_position: Vector2, enemy: EnemyCharacter, _direction: Vector2 = Vector2.ZERO) -> void:
	super.setup(skill, caster_position, enemy)
	
	# Use scaled damage
	self.damage = skill.get_scaled_damage()
	
	if targetenemy and is_instance_valid(targetenemy):
		targetenemy.enter_stun(global_position)
		
	AudioManager.play_sound("skill_thunderstrike_crackle")

func _on_startup_complete() -> void:
	_enable_hitbox()

func _apply_stun_effect() -> void:
	AudioManager.play_sound("skill_thunderstrike")
	if targetenemy and is_instance_valid(targetenemy):
		targetenemy.exit_skill()
	_disable_hitbox()
