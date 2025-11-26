extends Skill
class_name HealOverTime

@export var heal_per_tick: float = 5.0  # Lượng máu hồi mỗi lần tick
@export var tick_interval: float = 1.0  # Khoảng thời gian giữa các lần hồi máu (tick)

func _init():
	name = "Heal Over Time"
	element = "Water" # Hoặc Earth (đất) liên quan đến sự sống
	type = "buff"
	cooldown = 15.0
	duration = 5.0 # Kỹ năng kéo dài 5 giây (tổng cộng 5 tick)
	mana = 20.0
	texture = preload("res://assets/skills/icons_skill/48x48/skill_icons36.png") # Thay bằng icon phù hợp
	projectile_scene = preload("res://scenes/skills/buff/buffHeal.tscn")
	animation_name = "Heal"
