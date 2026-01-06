extends Skill
class_name ThunderStrike

func _init():
	name = "Thunder Strike"
	elemental_type = ElementsEnum.Elements.METAL
	type = "area"
	cooldown = 3.5
	duration = 1.5
	mana = 20
	animation_name = "ThunderStrike"
	texture_path = "res://assets/skills/icons_skill/48x48/skill_icons34.png"
	area_scene_path = "res://scenes/skills/area/metal/thunderstrike.tscn"
	damage = 10
