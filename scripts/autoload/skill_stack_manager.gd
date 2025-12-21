extends Node

# ✅ Stores skill data (levels preserved)
var table := {}  # { "Fireball": { "stack": 2, "level": 2, "unlocked": true } }
var skillbar := [null, null, null, null, null]

# ✅ Coins only
var coins: int = 0
signal coins_changed(new_amount: int)

func add_coins(amount: int = 5) -> void:
	coins += amount
	coins_changed.emit(coins)

func spend_coins(amount: int) -> bool:
	if coins < amount: return false
	coins -= amount
	coins_changed.emit(coins)
	return true

# ✅ Core skill stacking
func add_stack(skill: Skill, amount: int = 1) -> bool:
	var skill_name = skill.name
	
	if not table.has(skill_name):
		table[skill_name] = {
			"stack": 0,
			"level": skill.level,
			"unlocked": true
		}
	
	table[skill_name].stack += amount
	stack_changed.emit(skill_name, table[skill_name].stack)
	unlocked_changed.emit(skill_name, true)
	return true

func remove_stack(skill_name: String, amount: int = 1):
	if not table.has(skill_name): return
	table[skill_name].stack = max(0, table[skill_name].stack - amount)
	stack_changed.emit(skill_name, table[skill_name].stack)

func set_level(skill_name: String, new_level: int):
	if not table.has(skill_name):
		table[skill_name] = { "stack": 0, "level": new_level, "unlocked": false }
	else:
		table[skill_name].level = new_level
	level_changed.emit(skill_name, new_level)

func set_unlocked(skill_name: String):
	if not table.has(skill_name): return
	table[skill_name].unlocked = true
	unlocked_changed.emit(skill_name, true)

func get_skill_resource(skill_name: String) -> Skill:
	if not table.has(skill_name): return null
	
	# Recreate from SkillDatabase with correct level
	var skill_data = table[skill_name]
	var base_skill = SkillDatabase.get_skill_by_name(skill_name)
	if base_skill:
		base_skill.level = skill_data.level
		return base_skill.duplicate()
	return null

func get_stack(skill_name: String) -> int:
	return table.get(skill_name, {}).get("stack", 0)

func get_level(skill_name: String) -> int:
	return table.get(skill_name, {}).get("level", 1)

func get_unlocked(skill_name: String) -> bool:
	return table.get(skill_name, {}).get("unlocked", false)

# ✅ FIXED SAVE: Single data structure
func save_data() -> Dictionary:
	var save_table := {}
	for skill_name in table:
		var data = table[skill_name]
		save_table[skill_name] = {
			"stack": data.stack,
			"level": data.level,
			"unlocked": data.unlocked
		}
	
	return {
		"table": save_table,
		"skillbar": skillbar.duplicate(true),
		"coins": coins
	}

# ✅ REMOVED: save_skillbar_data() - now in save_data()

# ✅ FIXED LOAD: Handle BOTH skill_stack + skill_bar_data (backwards compatible)
func load_data(skill_stack: Dictionary = {}, skill_bar_data: Array = []) -> void:
	# Handle single arg (backwards compatible)
	if skill_stack is Dictionary and skill_bar_data is Array:
		# New format: skill_stack={table,skillbar,coins}
		if skill_stack.has("table"):
			table = skill_stack.table.duplicate(true)
		if skill_stack.has("skillbar"):
			skillbar = skill_stack.skillbar.duplicate(true)
		if skill_stack.has("coins"):
			coins = skill_stack.coins
			coins_changed.emit(coins)
	elif skill_stack is Dictionary:
		# Old format: just table
		table = skill_stack.duplicate(true)
	
	# Restore levels via database
	for skill_name in table:
		var skill_data = table[skill_name]
		var skill = SkillDatabase.get_skill_by_name(skill_name)
		if skill and skill_data.has("level"):
			skill.level = skill_data.level
	
	# Refresh UIs
	stack_changed.emit("", -1)
	level_changed.emit("", -1)
	coins_changed.emit(coins)

func get_skill_bar_data() -> Array:
	return skillbar.duplicate(true)

# Skillbar management
func set_skill_in_bar(slot_index: int, skill_name: String) -> void:
	if slot_index < 0 or slot_index >= skillbar.size() or not table.has(skill_name): return
	skillbar[slot_index] = skill_name
	skillbar_changed.emit(slot_index, skill_name)

func clear_skill_in_bar(slot_index: int) -> void:
	if slot_index < 0 or slot_index >= skillbar.size(): return
	skillbar[slot_index] = null
	skillbar_changed.emit(slot_index, "")

func find_skill_in_bar(skill_name: String) -> int:
	for i in range(skillbar.size()):
		if skillbar[i] == skill_name: return i
	return -1

func unequip_skill(skill_name: String) -> void:
	var index = find_skill_in_bar(skill_name)
	if index == -1: return
	clear_skill_in_bar(index)

func equip_skill(slot_index: int, skill_name: String) -> void:
	if slot_index < 0 or slot_index >= skillbar.size() or not table.has(skill_name): return
	set_skill_in_bar(slot_index, skill_name)

# Signals
signal stack_changed(skill_name: String, new_value: int)
signal level_changed(skill_name: String, new_level: int)
signal unlocked_changed(skill_name: String, new_unlocked: bool)
signal skillbar_changed(slot_index: int, skill_name: String)
