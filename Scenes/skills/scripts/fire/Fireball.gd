# res://skills/fire/Fireball.gd
extends Skill
class_name Fireball

func _init():
	name = "Fireball"
	element = ElementsEnum.Elements.FIRE
	type = "buff"
	cooldown = 20.0
	duration = 10.0
	speed = 0
	damage = 0
	mana = 30
	texture_path = "res://assets/skills/icons_skill/48x48/skill_fireball.png"
	animation_name = "Fireball"
	projectile_scene = preload("res://scenes/skills/buff/fire/fireball.tscn")
