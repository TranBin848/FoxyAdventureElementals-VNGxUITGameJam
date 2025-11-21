extends Skill
class_name WaterBall

func _init():
	name = "Water Ball"
	element = "Water"
	type = "multi_shot"
	cooldown = 3.5
	animation_name = "WaterBlast"
	texture = preload("res://assets/skills/icons_skill/48x48/skill_icons23.png")
	projectile_scene = preload("res://scenes/skills/area/water/waterSpikeArea.tscn")
	speed = 250
	damage = 2
