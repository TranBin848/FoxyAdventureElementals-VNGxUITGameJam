extends Skill
class_name WaterBall

func _init():
	name = "Water Ball"
	element = "Water"
	type = "multi_shot"
	cooldown = 1.5
	animation_name = "WaterBlast"
	texture = preload("res://assets/skills/icons_skill/48x48/skill_icons23.png")
	projectile_scene = preload("res://scenes/skills/projectiles/water/waterProjectile.tscn")
	speed = 250
	damage = 12
