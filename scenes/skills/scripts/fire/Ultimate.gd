extends Skill
class_name Ultimate

func _init():
	name = "Ultimate"
	elemental_type = ElementsEnum.Elements.NONE
	cooldown = 8.0
	type = "radial"
	texture_path = "res://assets/skills/icons_skill/48x48/skill_icons53.png"
	damage = 25
	speed = 200
	projectile_scene = preload("res://scenes/skills/projectiles/projectileBase.tscn")
