# res://skills/fire/FireShot.gd
extends Skill
class_name FireShot

func _init():
	name = "Fire Shot"
	element = ElementsEnum.Elements.FIRE
	type = "multi_shot"
	cooldown = 2.0
	speed = 350
	damage = 2
	mana = 30
	texture_path = "res://assets/skills/icons_skill/48x48/skill_icons4.png"
	animation_name = "Fire"
	projectile_scene = preload("res://scenes/skills/projectiles/fire/fireShotProjectile.tscn")
