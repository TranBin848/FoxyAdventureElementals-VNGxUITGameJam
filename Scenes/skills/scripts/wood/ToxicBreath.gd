# res://skills/fire/FireShot.gd
extends Skill
class_name ToxicBreath

func _init():
	name = "Toxic Breath"
	elemental_type = ElementsEnum.Elements.WOOD
	type = "single_shot"
	cooldown = 3.0
	speed = 0
	damage = 5
	mana = 10
	texture_path = "res://assets/skills/icons_skill/48x48/skill_icons12.png"
	animation_name = "ToxicBreath"
	projectile_scene = preload("res://scenes/skills/projectiles/wood/toxic_breath.tscn")
