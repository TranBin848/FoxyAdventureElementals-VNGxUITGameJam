extends AreaBase
class_name WaterSpikeArea

@export var knockback_force: float = 350.0 # Lực đẩy văng kẻ địch ra sau khi hút

func setup(skill: Skill, caster_position: Vector2, enemy: EnemyCharacter) -> void:
	# Gọi hàm setup của lớp cơ sở để gán thuộc tính, vị trí, và enemy
	super.setup(skill, caster_position, enemy)
	
	# 🎯 1. Vô hiệu hóa khả năng di chuyển của kẻ địch ngay lập tức
	if targetenemy and is_instance_valid(targetenemy):
		targetenemy.enter_skill(global_position)
		# Optional: Thay đổi animation của enemy sang trạng thái bị choáng/đứng yên
		# targetenemy.animated_sprite.play("stun")
		
# Hàm này được gọi khi animation khởi động (gai nước trồi lên) kết thúc
func _on_startup_animation_finished(skill: Skill):
	# Gọi lại logic của lớp cơ sở: dừng startup, bật main animation, bật HitArea2D
	super._on_startup_animation_finished(skill)
	await get_tree().create_timer(0.15).timeout
	# 🎯 2. Gây hiệu ứng Knockback (đẩy lên trời)
	if targetenemy and is_instance_valid(targetenemy):
		targetenemy.exit_skill()
		targetenemy.apply_knockback(self.global_position, knockback_force)

		
