# res://skills/fire/FireShot.gd
extends Skill
class_name WoodShot

func _init():
	name = "Wood Shot"
	element = ElementsEnum.Elements.WOOD
	type = "multi_shot"
	cooldown = 2.0
	speed = 350
	damage = 2
	mana = 30
	texture_path = "res://assets/skills/icons_skill/48x48/skill_icons38.png"
	animation_name = "WoodShot"
	projectile_scene = preload("res://scenes/skills/projectiles/wood/woodShotProjectile.tscn")
