extends Skill
class_name WaterSpike

func _init():
	name = "Water Spike"
	element = "Water"
	type = "area"
	cooldown = 3.5
	duration = 1.5
	animation_name = "WaterSpike"
	texture = preload("res://assets/skills/icons_skill/48x48/skill_icons19.png")
	area_scene = preload("res://scenes/skills/area/water/waterSpikeArea.tscn")
	damage = 2
