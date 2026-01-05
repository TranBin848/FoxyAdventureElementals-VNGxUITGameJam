class_name EnemyStateDead
extends EnemyState

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
	
	# HOOK HERE
	#GameProgressManager.trigger_event("KILL")
	
	# ✅ Global skill drop (element = enemy's element)
	_drop_skill_item()
	
func _drop_skill_item():
	# Element từ enemy → Global manager → Perfect leveled skill! + DEBUG
	var skill = SkillDropManager.roll_skill_drop(obj.elemental_type)
	if skill:
		print("🎲 [%s] Enemy(%s) → %s Lv%d" % [
			"Level%d" % (SkillDropManager.current_level + 1),
			ElementsEnum.Elements.keys()[obj.elemental_type],
			skill.name, 
			skill.level
		])
		
		var skill_drop = SKILL_DROP_SCENE.instantiate() as SkillDrop
		get_tree().current_scene.add_child(skill_drop)
		var skill_name = "%s Lv%d" % [skill.name, skill.level]
		skill_drop.setup_drop(skill)
		skill_drop.global_position = obj.global_position
		
		print("✅ [%s] Spawned %s drop at %.1f,%.1f" % [
			"Level%d" % (SkillDropManager.current_level + 1),
			skill_name,
			skill_drop.global_position.x,
			skill_drop.global_position.y
		])
	#else:
		#print("❌ [%s] %s enemy → NO DROP (%.0f%% chance)" % [
			#"Level%d" % (SkillDropManager.current_level + 1),
			#ElementsEnum.Elements.keys()[obj.elemental_type],
			#SkillDropManager.base_drop_chance[SkillDropManager.current_level] * 100
		#])


	
func _update( _delta ):
	if obj.animated_sprite:
		var time_ratio: float = timer / despawn_time
		obj.animated_sprite.modulate.a = time_ratio
		if shader_material != null:
			shader_material.set("shader_parameter/line_opacity", max_line_opaque * time_ratio)
			shader_material.set("shader_parameter/glow_opacity", max_glow_opaque * time_ratio)
			pass
	if update_timer(_delta):
		obj.queue_free()
	super._update(_delta)
	
	if obj.current_state == fsm.states.dead:
		if shader_material != null:
			shader_material.set("shader_parameter/line_opacity", max_line_opaque * time_ratio)
			shader_material.set("shader_parameter/glow_opacity", max_glow_opaque * time_ratio)
			pass
		obj.animated_sprite.modulate.a = time_ratio
	

func get_shader_values() -> void:
	if obj.animated_sprite:
		shader_material = obj.animated_sprite.material
		
		for item in shader_material.get_property_list():
			if (item.name == "shader_parameter/line_opacity"):
				max_line_opaque = item.hint
			if (item.name == "shader_parameter/glow_opacity"):
				max_glow_opaque = item.hint

func take_damage(direction: Variant, _damage: int = 1) -> void:
	pass
