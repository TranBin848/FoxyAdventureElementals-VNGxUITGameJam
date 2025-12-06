extends Node

var stack_table := {} # { "Fireball": 2, "IceShot": 3 }

func add_stack(skill_name: String, amount: int):
	if not stack_table.has(skill_name):
		stack_table[skill_name] = 0

	stack_table[skill_name] += amount
	emit_signal("stack_changed", skill_name, stack_table[skill_name])

func save_data() -> Dictionary:
	return stack_table.duplicate(true)

func load_data(data: Dictionary) -> void:
	stack_table = data.duplicate(true)
	emit_signal("stack_changed", "", -1) # báo SkillTree refresh toàn bộ

signal stack_changed(skill_name, new_value)
