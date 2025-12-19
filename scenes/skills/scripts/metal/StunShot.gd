extends Skill
class_name StunShot

func _init():
	name = "Stun Shot"
	element = ElementsEnum.Elements.METAL
	type = "single_shot"
	cooldown = 2.0
	speed = 200
	damage = 0
	mana = 30.0
	texture_path = "res://assets/skills/icons_skill/48x48/skill_icons5.png"
	animation_name = "Fire"
	projectile_scene = preload("res://scenes/skills/projectiles/metal/stun_shot_projectile.tscn")
