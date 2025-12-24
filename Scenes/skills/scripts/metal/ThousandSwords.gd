extends Skill
class_name ThousandSwords

func _init():
	name = "Thousand Swords"
	elemental_type = ElementsEnum.Elements.METAL
	type = "area"
	cooldown = 1
	duration = 15
	ground_targeted = true
	mana = 20
	texture_path = "res://assets/skills/icons_skill/48x48/skill_icons45.png"
	area_scene = preload("res://scenes/skills/area/metal/thousandSwords.tscn")
	damage = 5
