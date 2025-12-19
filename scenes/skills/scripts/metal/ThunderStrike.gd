extends Skill
class_name Thunderbolt

func _init():
	name = "Thunderbolt"
	element = ElementsEnum.Elements.METAL
	type = "area"
	cooldown = 3.5
	duration = 1.5
	mana = 20.0
	animation_name = "Thunderbolt"
	texture_path = "res://assets/skills/icons_skill/48x48/skill_icons34.png"
	area_scene = preload("res://scenes/skills/area/metal/thunderbolt.tscn")
	damage = 10
