# res://skills/fire/FireShot.gd
extends Skill
class_name FireShot

func _init():
	name = "Fire Shot"
	element = "Fire"
	type = "single_shot"
	cooldown = 1.0
	speed = 350
	damage = 15
	texture = preload("res://assets/skills/icons_skill/48x48/skill_icons4.png")
	animation_name = "Fire"
	projectile_scene = preload("res://scenes/skills/projectiles/fire/fireShotProjectile.tscn")
