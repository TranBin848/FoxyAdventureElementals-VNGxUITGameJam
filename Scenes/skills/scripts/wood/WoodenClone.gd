# res://skills/fire/FireShot.gd
extends Skill
class_name WoodenClone

func _init():
	name = "Wooden Clone"
	elemental_type = ElementsEnum.Elements.WOOD
	type = "single_shot"
	cooldown = 20.0
	duration = 10.0
	speed = 0
	damage = 0
	mana = 20
	texture_path = "res://assets/skills/icons_skill/48x48/skill_icons35.png"
	animation_name = ""
	projectile_scene_path = "res://scenes/skills/projectiles/wood/wooden_clone.tscn"
