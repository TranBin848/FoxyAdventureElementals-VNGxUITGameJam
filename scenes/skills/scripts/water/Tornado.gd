extends Skill
class_name Tornado

func _init():
	name = "Tornado"
	element = "Water"
	type = "single_shot"
	cooldown = 2.5
	animation_name = "WaterTornado"
	texture = preload("res://assets/skills/icons_skill/48x48/skill_icons24.png")
	projectile_scene = preload("res://scenes/skills/projectiles/water/waterTornadoProjectile.tscn")
	speed = 180
	damage = 20
