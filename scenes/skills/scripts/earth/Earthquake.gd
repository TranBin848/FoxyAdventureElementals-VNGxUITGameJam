extends Skill
class_name Earthquake

func _init():
	name = "Earthquake"
	element = ElementsEnum.Elements.EARTH
	type = "single_shot"
	cooldown = 2.5
	speed = 400
	damage = 10
	mana = 10.0
	texture_path = "res://assets/skills/icons_skill/48x48/skill_icons4.png"
	animation_name = "Earthquake"
	projectile_scene = preload("res://scenes/skills/projectiles/earth/earthquake_projectile.tscn")
