extends Skill
class_name Tornado

func _init():
	name = "Tornado"
	element = ElementsEnum.Elements.WATER
	type = "single_shot"
	cooldown = 5.0
	animation_name = "WaterTornado"
	texture_path = "res://assets/skills/icons_skill/48x48/skill_icons24.png"
	projectile_scene = preload("res://scenes/skills/projectiles/water/waterTornadoProjectile.tscn")
	speed = 180
	damage = 1.5
	mana = 40
