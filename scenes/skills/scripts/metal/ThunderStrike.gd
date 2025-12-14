extends Skill
class_name ThunderStrike

func _init():
	name = "Thunder Strike"
	element = "Metal"
	type = "area"
	cooldown = 3.5
	duration = 1.5
	mana = 20.0
	animation_name = "ThunderStrike"
	texture = preload("res://assets/skills/icons_skill/48x48/skill_icons34.png")
	area_scene = preload("res://scenes/skills/area/metal/thunderStrike.tscn")
	damage = 10
