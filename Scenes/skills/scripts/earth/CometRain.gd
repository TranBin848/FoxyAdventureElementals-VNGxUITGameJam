extends Skill
class_name CometRain

func _init():
	name = "Comet Rain"
	element = ElementsEnum.Elements.EARTH
	type = "area"
	ground_targeted = true
	duration = 10
	cooldown = 3
	speed = 0
	damage = 0
	mana = 10.0
	texture_path = "res://assets/skills/icons_skill/48x48/skill_icons28.png"
	area_scene = preload("res://scenes/skills/area/earth/cometRain.tscn")
