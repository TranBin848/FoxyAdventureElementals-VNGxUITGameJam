extends EnemyState
class_name EnemyStateDead

@export var despawn_time: float = 2
const SKILL_DROP_SCENE: PackedScene = preload("res://scenes/skills/base/skill_drop/skill_drop.tscn")

var shader_material: Material
var max_line_opaque: float = 0
var max_glow_opaque: float = 0

func _enter() -> void:
	obj.change_animation("dead")
	obj.velocity.x = 0
	obj.disable_collision()
	timer = despawn_time
	get_shader_values()
	_drop_skill_item()
	
func _update( _delta ):
	var time_ratio: float = timer / despawn_time
	obj.animated_sprite.modulate.a = time_ratio
	if shader_material != null:
		shader_material.set("shader_parameter/line_opacity", max_line_opaque * time_ratio)
		shader_material.set("shader_parameter/glow_opacity", max_glow_opaque * time_ratio)
		pass
	if update_timer(_delta):
		obj.queue_free()
	super._update(_delta)

func get_shader_values() -> void:
	shader_material = obj.animated_sprite.material
	
	for item in shader_material.get_property_list():
		if (item.name == "shader_parameter/line_opacity"):
			max_line_opaque = item.hint
		if (item.name == "shader_parameter/glow_opacity"):
			max_glow_opaque = item.hint

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
			
			#print("✅ Enemy dropped skill:", skill_name)
