extends Node

# --- STATE (Private - only modified internally) ---
var _skill_data := {}  # {skill_name: {level: int, unlocked: bool}}
var _skillbar := [null, null, null, null, null]
var _stacks := {}  # {skill_name: int}
var _skills_discovered_history: Dictionary = {}
var _coins: int = 0

# --- SIGNALS (Components listen to these) ---
signal state_changed(state: Dictionary)  # Emits full state
signal skill_discovered(skill_name: String)
signal skill_unlocked(skill_name: String)
signal skill_leveled_up(skill_name: String, new_level: int)
signal skill_equipped(slot_index: int, skill_name: String)
signal skill_unequipped(slot_index: int, skill_name: String)
signal stack_changed(skill_name: String, amount: int)
signal coins_changed(amount: int)

# --- PUBLIC API (Commands - only way to modify state) ---

func consume_skill_use(skill_name: String) -> void:
	if is_unlocked(skill_name):
		return

	var current_stacks = get_stacks(skill_name)
	if current_stacks <= 0:
		return

	_stacks[skill_name] = current_stacks - 1
	stack_changed.emit(skill_name, _stacks[skill_name])
	
	print("Used 1 stack of %s (Remaining: %d)" % [skill_name, _stacks[skill_name]])

	if _stacks[skill_name] <= 0:
		var slot_index = find_skill_slot(skill_name)
		if slot_index != -1:
			unequip_skill(slot_index)
			print("%s ran out! Unequipping..." % skill_name)

func collect_skill(skill_name: String, stack_amount: int = 1) -> void:
	GameProgressManager.trigger_event("SKILL_SCROLL")
	
	if not SkillDatabase.get_skill_by_name(skill_name):
		push_error("Unknown skill: %s" % skill_name)
		return
		
	if not _skill_data.has(skill_name):
		_skill_data[skill_name] = {
			"level": 1,        # Start at level 1
			"unlocked": false
		}
		
	if get_stacks(skill_name) == 0 and stack_amount > 0:
		skill_discovered.emit(skill_name)
		_skills_discovered_history[skill_name] = true
		print("✨ NEW SKILL DISCOVERED: %s" % skill_name)
	
	_add_stacks(skill_name, stack_amount)
	
	if stack_amount > 0:
		if not (skill_name in _skillbar):
			var empty_slot = -1
			for i in range(_skillbar.size()):
				if _skillbar[i] == null:
					empty_slot = i
					break

			if empty_slot != -1:
				equip_skill(empty_slot, skill_name)
				print("⚡ Auto-equipped %s to slot %d" % [skill_name, empty_slot])
		
	print("📦 Collected +%d %s (Total: %d stacks, Level: %d)" % [
		stack_amount, 
		skill_name, 
		get_stacks(skill_name),
		get_level(skill_name)
	])

func unlock_skill(skill_name: String, stack_cost: int = 0) -> bool:
	if is_unlocked(skill_name):
		return false
	
	if get_stacks(skill_name) < stack_cost:
		return false
	
	_remove_stacks(skill_name, stack_cost)
	_set_unlocked(skill_name, true)
	skill_unlocked.emit(skill_name)
	state_changed.emit(get_state())
	return true

func upgrade_skill(skill_name: String, stack_cost: int) -> bool:
	if not is_unlocked(skill_name):
		return false
	
	var current_level = get_level(skill_name)
	if current_level >= 10:
		return false
	
	if get_stacks(skill_name) < stack_cost:
		return false
	
	_remove_stacks(skill_name, stack_cost)
	_set_level(skill_name, current_level + 1)
	skill_leveled_up.emit(skill_name, current_level + 1)
	state_changed.emit(get_state())
	return true

func equip_skill(slot_index: int, skill_name: String) -> bool:
	if slot_index < 0 or slot_index >= _skillbar.size():
		return false
	
	if not is_unlocked(skill_name) and get_stacks(skill_name) == 0:
		return false
	
	var old_skill = _skillbar[slot_index]
	if old_skill:
		skill_unequipped.emit(slot_index, old_skill)
	
	_skillbar[slot_index] = skill_name
	skill_equipped.emit(slot_index, skill_name)
	state_changed.emit(get_state())
	return true

func unequip_skill(slot_index: int) -> bool:
	if slot_index < 0 or slot_index >= _skillbar.size():
		return false
	
	var skill_name = _skillbar[slot_index]
	if not skill_name:
		return false
	
	_skillbar[slot_index] = null
	skill_unequipped.emit(slot_index, skill_name)
	state_changed.emit(get_state())
	return true

# --- PUBLIC QUERIES (Read-only access) ---

func get_state() -> Dictionary:
	return {
		"skill_data": _skill_data.duplicate(true),
		"skillbar": _skillbar.duplicate(),
		"stacks": _stacks.duplicate(),
		"coins": _coins
	}

func is_unlocked(skill_name: String) -> bool:
	return _skill_data.get(skill_name, {}).get("unlocked", false)

func get_level(skill_name: String) -> int:
	return _skill_data.get(skill_name, {}).get("level", 1)  # Default to 1, not 0

func get_stacks(skill_name: String) -> int:
	return _stacks.get(skill_name, 0)

func get_skillbar() -> Array:
	return _skillbar.duplicate()

func find_skill_slot(skill_name: String) -> int:
	return _skillbar.find(skill_name)

func get_skill_resource(skill_name: String) -> Skill:
	"""Get a configured skill resource for gameplay - scaling handled automatically"""
	if not is_unlocked(skill_name) and get_stacks(skill_name) == 0:
		return null
	
	var base = SkillDatabase.get_skill_by_name(skill_name)
	if not base:
		return null
	
	# Just return the base skill - it will query SkillTreeManager for its level
	# when get_scaled_damage() etc. are called
	return base

# --- PRIVATE HELPERS ---

func _add_stacks(skill_name: String, amount: int) -> void:
	if not _stacks.has(skill_name):
		_stacks[skill_name] = 0
	_stacks[skill_name] += amount
	stack_changed.emit(skill_name, _stacks[skill_name])

func _remove_stacks(skill_name: String, amount: int) -> void:
	if _stacks.has(skill_name):
		_stacks[skill_name] = max(0, _stacks[skill_name] - amount)
		stack_changed.emit(skill_name, _stacks[skill_name])

func _set_unlocked(skill_name: String, value: bool) -> void:
	if not _skill_data.has(skill_name):
		_skill_data[skill_name] = {"level": 1, "unlocked": false}
	_skill_data[skill_name].unlocked = value

func _set_level(skill_name: String, level: int) -> void:
	if not _skill_data.has(skill_name):
		_skill_data[skill_name] = {"level": 1, "unlocked": false}
	_skill_data[skill_name].level = level

func save_data() -> Dictionary:
	return {
		"skill_data": _skill_data.duplicate(true),
		"skillbar": _skillbar.duplicate(),
		"stacks": _stacks.duplicate(),
		"history": _skills_discovered_history.duplicate(),
		"coins": _coins
	}

func load_data(data: Dictionary) -> void:
	if data.is_empty():
		return
	
	print("📂 LOADING SkillTreeManager...")
	
	_skill_data = data.get("skill_data", {}).duplicate(true)
	_stacks = data.get("stacks", {}).duplicate()
	_coins = data.get("coins", 0)
	_skills_discovered_history = data.get("history", {}).duplicate()
	
	_skillbar.fill(null)
	var saved_bar = data.get("skillbar", [])
	
	for i in range(min(saved_bar.size(), _skillbar.size())):
		var skill_name = saved_bar[i]
		
		if skill_name is String and SkillDatabase.get_skill_by_name(skill_name):
			_skillbar[i] = skill_name
		else:
			_skillbar[i] = null
			
	print("✅ Load Complete. Syncing UI...")
	state_changed.emit(get_state())
