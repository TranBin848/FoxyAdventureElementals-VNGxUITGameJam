extends Skill
class_name Thunderbolt

func _init():
	name = "Thunderbolt"
	elemental_type = ElementsEnum.Elements.METAL
	type = "single_shot"
	damage = 0
	texture_path = "res://assets/skills/icons_skill/48x48/skill_icons5.png"
	projectile_scene_path = "res://scenes/skills/projectiles/metal/thunderbolt.tscn"
