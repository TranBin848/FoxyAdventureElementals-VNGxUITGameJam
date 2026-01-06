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
	# 1. If unlocked, we don't consume stacks (Infinite use)
	if is_unlocked(skill_name):
		return

	# 2. Check if we actually have stacks
	var current_stacks = get_stacks(skill_name)
	if current_stacks <= 0:
		return

	# 3. Reduce stack count
	# We use existing logic but negative. 
	# (Assuming collect_skill handles addition, we essentially add -1)
	_stacks[skill_name] = current_stacks - 1
	stack_changed.emit(skill_name, _stacks[skill_name])
	
	print("Used 1 stack of %s (Remaining: %d)" % [skill_name, _stacks[skill_name]])

	# 4. Auto-Unequip if we just hit 0
	if _stacks[skill_name] <= 0:
		var slot_index = find_skill_slot(skill_name)
		if slot_index != -1:
			unequip_skill(slot_index)
			print("%s ran out! Unequipping..." % skill_name)

func collect_skill(skill_name: String, stack_amount: int = 1) -> void:
	"""Called when player picks up a skill in the world"""
	if not SkillDatabase.get_skill_by_name(skill_name):
		push_error("Unknown skill: %s" % skill_name)
		return
		
	if get_stacks(skill_name) == 0 and stack_amount > 0:
		skill_discovered.emit(skill_name)
		_skills_discovered_history[skill_name] = true
		print("✨ NEW SKILL DISCOVERED: %s" % skill_name)
	
	_add_stacks(skill_name, stack_amount)
	
	if stack_amount > 0:
		# Check if it's already on the bar to avoid duplicates
		if not (skill_name in _skillbar):
		# Find the first empty slot (null)
			var empty_slot = -1
			for i in range(_skillbar.size()):
				if _skillbar[i] == null:
					empty_slot = i
					break

				# If we found a spot, equip it!
			if empty_slot != -1:
				equip_skill(empty_slot, skill_name)
				print("⚡ Auto-equipped %s to slot %d" % [skill_name, empty_slot])
		
	print("📦 Collected +%d %s (Total: %d)" % [stack_amount, skill_name, get_stacks(skill_name)])

func unlock_skill(skill_name: String, stack_cost: int = 0) -> bool:
	"""Unlock a skill permanently using stacks"""
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
	"""Upgrade skill level using stacks"""
	if not is_unlocked(skill_name):
		return false
	
	var current_level = get_level(skill_name)
	if current_level >= 3:
		return false
	
	if get_stacks(skill_name) < stack_cost:
		return false
	
	_remove_stacks(skill_name, stack_cost)
	_set_level(skill_name, current_level + 1)
	skill_leveled_up.emit(skill_name, current_level + 1)
	state_changed.emit(get_state())
	return true

func equip_skill(slot_index: int, skill_name: String) -> bool:
	"""Equip a skill to the action bar"""
	if slot_index < 0 or slot_index >= _skillbar.size():
		return false
	
	if not is_unlocked(skill_name) and get_stacks(skill_name) == 0:
		return false
	
	# Unequip old skill if exists
	var old_skill = _skillbar[slot_index]
	if old_skill:
		skill_unequipped.emit(slot_index, old_skill)
	
	_skillbar[slot_index] = skill_name
	skill_equipped.emit(slot_index, skill_name)
	state_changed.emit(get_state())
	return true

func unequip_skill(slot_index: int) -> bool:
	"""Remove skill from action bar"""
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
	"""Get complete state snapshot for UI sync"""
	return {
		"skill_data": _skill_data.duplicate(true),
		"skillbar": _skillbar.duplicate(),
		"stacks": _stacks.duplicate(),
		"coins": _coins
	}

func is_unlocked(skill_name: String) -> bool:
	return _skill_data.get(skill_name, {}).get("unlocked", false)

func get_level(skill_name: String) -> int:
	return _skill_data.get(skill_name, {}).get("level", 0)

func get_stacks(skill_name: String) -> int:
	return _stacks.get(skill_name, 0)

func get_skillbar() -> Array:
	return _skillbar.duplicate()

func find_skill_slot(skill_name: String) -> int:
	return _skillbar.find(skill_name)

func get_skill_resource(skill_name: String) -> Skill:
	"""Get a configured skill resource for gameplay"""
	if not is_unlocked(skill_name) and get_stacks(skill_name) == 0:
		return null
	
	var base = SkillDatabase.get_skill_by_name(skill_name)
	if not base:
		return null
	
	var instance = base.duplicate()
	instance.level = get_level(skill_name)
	return instance

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
	
	# 1. State Replacement (Silent)
	# We update internal variables directly without triggering logic functions
	# This prevents individual signals (equipped, stack_changed) from firing during the loop
	
	_skill_data = data.get("skill_data", {}).duplicate(true)
	_stacks = data.get("stacks", {}).duplicate()
	_coins = data.get("coins", 0)
	_skills_discovered_history = data.get("history", {}).duplicate()
	
	# 2. Skillbar Restoration
	# We clear and fill the array. We do NOT call equip_skill() here, 
	# because we don't want runtime side effects during a load.
	_skillbar.fill(null)
	var saved_bar = data.get("skillbar", [])
	
	for i in range(min(saved_bar.size(), _skillbar.size())):
		var skill_name = saved_bar[i]
		
		# Validation: Ensure skill actually exists in DB
		if skill_name is String and SkillDatabase.get_skill_by_name(skill_name):
			_skillbar[i] = skill_name
		else:
			_skillbar[i] = null
			
	print("✅ Load Complete. Syncing UI...")
	
	# 3. The "Single Source of Truth" Handoff
	# Emit ONE signal telling all UI components to look at the new data.
	state_changed.emit(get_state())
