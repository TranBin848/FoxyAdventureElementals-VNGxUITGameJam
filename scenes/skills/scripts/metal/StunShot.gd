extends Skill
class_name StunShot

func _init():
	name = "Stun Shot"
	elemental_type = ElementsEnum.Elements.METAL
	type = "single_shot"
	texture_path = "res://assets/skills/icons_skill/48x48/skill_icons5.png"
	projectile_scene = preload("res://scenes/skills/projectiles/metal/stun_shot_projectile.tscn")
