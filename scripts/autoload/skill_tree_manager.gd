extends Node

# --- DATA ---
var skill_data := {} 
var skillbar := [null, null, null, null, null]
var coins: int = 0

# --- RUNTIME DATA ---
var runtime_stacks := {} 

# --- SIGNALS ---
signal coins_changed(new_amount: int)
signal skill_unlocked(skill_name: String)
signal skill_leveled_up(skill_name: String, new_level: int)
signal skillbar_changed(slot_index: int, skill_name: String)
signal stack_changed(skill_name: String, new_stack_count: int)

# --- RUNTIME STACK LOGIC (ĐÃ SỬA) ---
# Sửa tham số từ 'skill_name: String' thành 'skill: Skill' để khớp với code cũ
func add_stack(skill: Skill, amount: int = 1) -> void:
	if skill == null: return
	
	var skill_name = skill.name # Lấy tên từ Skill Resource
	
	if not runtime_stacks.has(skill_name):
		runtime_stacks[skill_name] = 0
	
	runtime_stacks[skill_name] += amount
	stack_changed.emit(skill_name, runtime_stacks[skill_name])

func get_stack(skill_name: String) -> int:
	return runtime_stacks.get(skill_name, 0)

func reset_all_stacks() -> void:
	runtime_stacks.clear()
	for s_name in skill_data.keys():
		stack_changed.emit(s_name, 0)

# --- PERMANENT SKILL TREE LOGIC ---
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

func is_unlocked(skill_name: String) -> bool:
	return skill_data.get(skill_name, {}).get("unlocked", false)

func get_level(skill_name: String) -> int:
	return skill_data.get(skill_name, {}).get("level", 1)

func get_skill_resource(skill_name: String) -> Skill:
	if not is_unlocked(skill_name): return null
	var base_skill = SkillDatabase.new().get_skill_by_name(skill_name)
	if base_skill:
		base_skill.level = get_level(skill_name)
		return base_skill.duplicate()
	return null

# --- SKILL BAR ---
func set_skill_in_bar(slot_index: int, skill_name: String) -> void:
	if slot_index < 0 or slot_index >= skillbar.size(): return
	if not is_unlocked(skill_name): return
	skillbar[slot_index] = skill_name
	skillbar_changed.emit(slot_index, skill_name)

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

# --- SAVE SYSTEM ---
func save_data() -> Dictionary:
	return {
		"skill_data": skill_data.duplicate(true),
		"skillbar": skillbar.duplicate(true),
		"coins": coins
	}

# --- LOAD SYSTEM ---
func load_data(data: Dictionary) -> void:
	reset_all_stacks()

	if data.is_empty(): return
	
	if data.has("skill_data"):
		skill_data = data["skill_data"].duplicate(true)
	if data.has("skillbar"):
		skillbar = data["skillbar"].duplicate(true)
	if data.has("coins"):
		coins = data["coins"]
		
	coins_changed.emit(coins)
	for i in range(skillbar.size()):
		skillbar_changed.emit(i, skillbar[i] if skillbar[i] else "")
