# res://skills/buff/earth/burrow.gd
extends Skill
class_name Burrow

func _init():
	name = "Burrow"
	element = ElementsEnum.Elements.EARTH
	type = "buff"
	cooldown = 90.0
	duration = 15.0
	speed = 0
	damage = 0
	mana = 30
	texture_path = "res://assets/skills/icons_skill/48x48/skill_icons26.png"
	animation_name = "burrow"
	projectile_scene = preload("res://scenes/skills/buff/earth/burrow.tscn")
