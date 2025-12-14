extends "res://Scenes/enemies/states/dead.gd"

func _enter() -> void:
	obj.change_animation("dead")
	obj.velocity.x = 0
	obj.disable_collision()
	timer = despawn_time
	get_shader_values()
	if(obj.level == obj.max_level and obj.number_of_skill_drop > 0): _drop_skill_item()
	obj.split()
