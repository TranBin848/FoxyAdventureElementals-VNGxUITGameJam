# res://skills/fire/FireShot.gd
extends Skill
class_name FireExplosion

func _init():
	name = "Fire Explosion"
	element = "Fire"
	type = "single_shot"
	cooldown = 2.0
	speed = 500
	damage = 4
	texture = preload("res://assets/skills/icons_skill/48x48/skill_icons3.png")
	animation_name = "FireExplosion"
	projectile_scene = preload("res://Scenes/skills/projectiles/fire/fireExplosionProjectile.tscn")
