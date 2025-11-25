extends EnemyState
@export var despawn_time: float = 2
const SKILL_DROP_SCENE: PackedScene = preload("res://scenes/skills/base/skill_drop/skill_drop.tscn")

func _enter() -> void:
	obj.change_animation("dead")
	obj.velocity.x = 0
	obj.disable_collision()
	timer = despawn_time
	_drop_skill_item()
	
func _update( _delta ):
	if update_timer(_delta):
		obj.queue_free()

func take_damage(direction: Variant, damage: int = 1) -> void:
	pass

func _drop_skill_item():
	if obj.skill_to_drop and SKILL_DROP_SCENE:
		var skill_drop = SKILL_DROP_SCENE.instantiate() as SkillDrop
		
		if skill_drop:
			# 1. Thiết lập thông tin Skill
			var skill_name = obj.skill_to_drop.new().name # Lấy tên từ resource instance
			skill_drop.setup_drop(obj.skill_to_drop, skill_name, obj.skill_icon_path)
			
			# 2. Đặt vị trí
			skill_drop.global_position = obj.global_position
			
			# 3. Thêm vào Scene
			get_tree().current_scene.add_child(skill_drop)
			
			# print("✅ Enemy dropped skill:", skill_name)
