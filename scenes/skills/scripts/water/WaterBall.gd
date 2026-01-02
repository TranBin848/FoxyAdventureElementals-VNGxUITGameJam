extends Skill
class_name WaterBall

func _init():
	name = "Water Ball"
	elemental_type = ElementsEnum.Elements.WATER
	type = "multi_shot"
	cooldown = 3.5
	animation_name = "WaterBlast"
	texture_path = "res://assets/skills/icons_skill/48x48/skill_icons23.png"
	projectile_scene = preload("res://scenes/skills/projectiles/water/waterBlastProjectile.tscn")
	speed = 250
	damage = 2
	mana = 5
