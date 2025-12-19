# res://skills/fire/FireShot.gd
extends Skill
class_name FireExplosion

func _init():
	name = "Fire Explosion"
	element = ElementsEnum.Elements.FIRE
	type = "single_shot"
	cooldown = 2.0
	speed = 500
	damage = 4
	mana = 40.0
	texture_path = "res://assets/skills/icons_skill/48x48/skill_icons3.png"
	animation_name = "FireExplosion"
	projectile_scene = preload("res://scenes/skills/projectiles/fire/fireExplosionProjectile.tscn")
