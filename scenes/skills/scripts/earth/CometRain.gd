extends Skill
class_name CometRain

func _init():
	name = "Comet Rain"
	elemental_type = ElementsEnum.Elements.EARTH
	type = "area"
	ground_targeted = true
	duration = 10
	cooldown = 3
	speed = 0
	damage = 10
	mana = 10
	texture_path = "res://assets/skills/icons_skill/48x48/skill_icons28.png"
	area_scene_path = "res://scenes/skills/area/earth/cometRain.tscn"
