extends Skill
class_name WaterSpike

func _init():
	name = "Water Spike"
	elemental_type = ElementsEnum.Elements.WATER
	type = "area"
	cooldown = 3.5
	duration = 1.5
	mana = 20
	animation_name = "WaterSpike"
	texture_path = "res://assets/skills/icons_skill/48x48/skill_icons11.png"
	area_scene_path = "res://scenes/skills/area/water/waterSpikeArea.tscn"
	damage = 10
