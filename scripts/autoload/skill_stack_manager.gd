extends Node

var table := {} # { "Fireball": { "stack": 2, "level": 1 } }
var skillbar:= []

func add_stack(skill_name: String, amount: int):
	if not table.has(skill_name):
		table[skill_name] = { "stack": 0, "level": 1, "unlocked": false}

	table[skill_name].stack += amount
	emit_signal("stack_changed", skill_name, table[skill_name].stack)
	
func remove_stack(skill_name: String, amount: int = 1):
	if not table.has(skill_name): return

	table[skill_name].stack = max(0, table[skill_name].stack - amount)
	emit_signal("stack_changed", skill_name, table[skill_name].stack)

func set_level(skill_name: String, new_level: int):
	if not table.has(skill_name):
		table[skill_name] = { "stack": 0, "level": new_level }
	else:
		table[skill_name].level = new_level

	emit_signal("level_changed", skill_name, new_level)

func set_unlocked(skill_name: String):
	if not table.has(skill_name): return
	else:
		table[skill_name].unlocked = true
	
	emit_signal("unlocked_changed", true)
func get_stack(skill_name: String) -> int:
	return table.get(skill_name, {}).get("stack", 0)

func get_level(skill_name: String) -> int:
	return table.get(skill_name, {}).get("level", 1)

func get_unlocked(skill_name: String) -> int:
	return table.get(skill_name, {}).get("unlocked", false)

# SAVE / LOAD
func save_data() -> Dictionary:
	return table.duplicate(true)

func load_data(data: Dictionary, skillbardata: Array = []) -> void:
	table = data.duplicate(true)
	skillbar = skillbardata.duplicate(true)
	emit_signal("stack_changed", "", -1)
	emit_signal("level_changed", "", -1)

func get_skill_bar_data() -> Array:
	return skillbar

signal stack_changed(skill_name, new_value)
signal level_changed(skill_name, new_level)
signal unlocked_changed(skill_name, new_unlocked)
