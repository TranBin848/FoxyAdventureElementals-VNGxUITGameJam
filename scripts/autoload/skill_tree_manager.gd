extends Node

# --- DATA ---
var skill_data := {} 
var skillbar := [null, null, null, null, null]  # Equipped skill names
var coins: int = 0

# --- RUNTIME DATA ---
var runtime_stacks := {}  # ALL stacks (equipped + inventory)

# --- SIGNALS ---
signal coins_changed(new_amount: int)
signal skill_unlocked(skill_name: String)
signal skill_leveled_up(skill_name: String, new_level: int)
signal skillbar_changed(slot_index: int, skill_name: String)
signal stack_changed(skill_name: String, new_stack_count: int)

# --- RUNTIME STACK LOGIC (MERGED) ---
func add_stack(skill: Skill, amount: int = 1) -> void:
	if skill == null: return
	
	var skill_name = skill.name
	
	# 🔥 MERGE: If skill is equipped, stacks go to equipped slot
	var equipped_slot = find_skill_in_bar(skill_name)
	if equipped_slot != -1:
		print("DEBUG: Stack MERGED to equipped slot %d: +%d %s" % [equipped_slot, amount, skill_name])
	else:
		print("DEBUG: Stack ADDED to inventory: +%d %s" % [amount, skill_name])
	
	if not runtime_stacks.has(skill_name):
		runtime_stacks[skill_name] = 0
	
	runtime_stacks[skill_name] += amount
	stack_changed.emit(skill_name, runtime_stacks[skill_name])

func remove_stack(skill: Skill, amount: int) -> void:
	if skill == null: return
	
	var skill_name = skill.name
	if runtime_stacks.has(skill_name):
		runtime_stacks[skill_name] = max(0, runtime_stacks[skill_name] - amount)
		stack_changed.emit(skill_name, runtime_stacks[skill_name])

func get_skill_stack(skill_name: String) -> int:
	return runtime_stacks.get(skill_name, 0)

func get_total_stacks() -> int:
	var total = 0
	for stack in runtime_stacks.values():
		total += stack
	return total

func reset_all_stacks() -> void:
	runtime_stacks.clear()

# --- PERMANENT SKILL TREE LOGIC (unchanged) ---
func unlock_skill(skill_name: String) -> void:
	if not skill_data.has(skill_name):
		skill_data[skill_name] = { "level": 1, "unlocked": true }
	else:
		skill_data[skill_name].unlocked = true
	skill_unlocked.emit(skill_name)

func level_up_skill(skill_name: String) -> void:
	if not skill_data.has(skill_name):
		skill_data[skill_name] = { "level": 1, "unlocked": false }
	
	skill_data[skill_name].level += 1
	skill_leveled_up.emit(skill_name, skill_data[skill_name].level)

func get_unlocked(skill_name: String) -> bool:
	return skill_data.get(skill_name, {}).get("unlocked", false)

func get_level(skill_name: String) -> int:
	return skill_data.get(skill_name, {}).get("level", 0)
	
func set_level(skill_name: String, level: int) -> void:
	skill_data[skill_name].level = level

func get_skill_resource(skill_name: String) -> Skill:
	if not get_unlocked(skill_name): return null
	var base_skill = SkillDatabase.get_skill_by_name(skill_name)
	if base_skill:
		base_skill.level = get_level(skill_name)
		return base_skill.duplicate()
	return null

# --- SKILL BAR (MERGED LOGIC) ---
func set_skill_in_bar(slot_index: int, skill_name: String) -> void:
	if slot_index < 0 or slot_index >= skillbar.size(): 
		print("DEBUG: set_skill_in_bar - invalid slot %d" % slot_index)
		return
	if skill_name != "" and not get_unlocked(skill_name): 
		print("DEBUG: set_skill_in_bar - '%s' not unlocked" % skill_name)
		return
	
	# 🔥 TRANSFER stacks from inventory to equipped slot
	var old_skill = skillbar[slot_index]
	if old_skill and old_skill != skill_name:
		print("DEBUG: SWAP - Transfer %d stacks from '%s' → inventory" % [get_skill_stack(old_skill), old_skill])
	
	skillbar[slot_index] = skill_name
	print("DEBUG: EQUIPPED '%s' to slot %d (stacks: %d)" % [skill_name, slot_index, get_skill_stack(skill_name)])
	skillbar_changed.emit(slot_index, skill_name)

func clear_skill_in_bar(slot_index: int) -> void:
	if slot_index < 0 or slot_index >= skillbar.size():
		print("DEBUG: clear_skill_in_bar - invalid slot %d" % slot_index)
		return
	
	var old_skill = skillbar[slot_index]
	skillbar[slot_index] = null
	if old_skill:
		print("DEBUG: UNEQUIPPED '%s' from slot %d → stacks: %d" % [old_skill, slot_index, get_skill_stack(old_skill)])
	skillbar_changed.emit(slot_index, "")

func unequip_skill(skill_name: String) -> void:
	var slot = find_skill_in_bar(skill_name)
	if slot != -1:
		clear_skill_in_bar(slot)

func equip_skill(slot_index: int, skill_name: String) -> void:
	set_skill_in_bar(slot_index, skill_name)

func find_skill_in_bar(skill_name: String) -> int:
	for i in skillbar.size():
		if skillbar[i] == skill_name:
			print("DEBUG: find_skill_in_bar - '%s' found at slot %d" % [skill_name, i])
			return i
	print("DEBUG: find_skill_in_bar - '%s' not found" % skill_name)
	return -1

func get_skill_bar_data() -> Array:
	return skillbar.duplicate(true)

# --- ECONOMY ---
func add_coins(amount: int = 5) -> void:
	coins += amount
	coins_changed.emit(coins)

func spend_coins(amount: int) -> bool:
	if coins < amount: return false
	coins -= amount
	coins_changed.emit(coins)
	return true

# --- SAVE/LOAD (SAME JSON LOGIC) ---
func save_data() -> Dictionary:
	print("DEBUG: === SAVING SKILLTREE (MERGED) ===")
	print("DEBUG: Total stacks: %d across %d skills" % [get_total_stacks(), runtime_stacks.size()])
	
	var skillbar_indices = []
	for i in skillbar.size():
		var skill_name = skillbar[i]
		if skill_name == null:
			skillbar_indices.append(null)
			print("DEBUG: skillbar[%d] = null → %s" % [i, "null"])
		else:
			var index = SkillDatabase.get_skill_index(skill_name)
			skillbar_indices.append(index)
			print("DEBUG: skillbar[%d] = '%s' → index %d (stacks: %d)" % [i, skill_name, index, get_skill_stack(skill_name)])
	
	var result = {
		"skill_data": skill_data.duplicate(true),
		"skillbar": skillbar_indices,
		"coins": coins,
		"runtime_stacks": runtime_stacks.duplicate(true)  # 🔥 SAVE ALL STACKS
	}
	print("DEBUG: SAVED skillbar: ", skillbar_indices)
	return result

func load_data(data: Dictionary) -> void:
	print("DEBUG: === LOADING SKILLTREE (MERGED) ===")
	
	reset_all_stacks()
	if data.is_empty(): return
	
	if data.has("skill_data"):
		skill_data = data["skill_data"].duplicate(true)
	if data.has("runtime_stacks"):  # 🔥 LOAD ALL STACKS
		runtime_stacks = data["runtime_stacks"].duplicate(true)
	if data.has("skillbar"):
		var skillbar_indices = data["skillbar"]
		for i in skillbar_indices.size():
			var index = skillbar_indices[i]
			if index == null:
				skillbar[i] = null
			else:
				var skill_name = SkillDatabase.get_skill_name_by_index(index)
				if skill_name != "":
					unlock_skill(skill_name)
					set_skill_in_bar(i, skill_name)
	if data.has("coins"):
		coins = data["coins"]
	
	coins_changed.emit(coins)
	for i in range(skillbar.size()):
		skillbar_changed.emit(i, skillbar[i] if skillbar[i] else "")
	
	print("DEBUG: Loaded %d total stacks!" % get_total_stacks())
