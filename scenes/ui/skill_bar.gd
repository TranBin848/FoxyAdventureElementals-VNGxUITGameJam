extends HBoxContainer
class_name SkillBar

const ERROR_DISPLAY_TIME: float = 2.0 
const PLAYER_RETRY_DELAY: float = 0.1
const MAX_RETRIES: int = 50  # 5 seconds max

var slots: Array
var skills: Array = []  # Now stores Skill instances, not Scripts
var alert_label: Label = null 
var player: Player = null
var retry_count: int = 0

func _ready() -> void:
	slots = get_children()
	
	# ✅ DEFERRED: Wait for player to load
	call_deferred("setup_player_connection")
	
	alert_label = get_tree().root.find_child("ErrorLabel", true, false) as Label
	SkillStackManager.skillbar_changed.connect(on_skillbar_changed)
	
# ✅ RETRY until player loads
func setup_player_connection():
	print("🔍 [Retry %d] Searching for player..." % retry_count)
	
	player = get_tree().get_first_node_in_group("player")
	if not player:
		player = find_player_by_class()
	
	if player:
		# ✅ AUTO-ADD group if missing
		if not player.is_in_group("player"):
			player.add_to_group("player")
			print("✅ AUTO-ADDED %s to 'player' group!" % player.name)
		
		# ✅ Check & connect signal
		if player.has_signal("skill_collected"):
			player.skill_collected.connect(_on_skill_collected)
			print("👤 ✅ Player '%s' connected! Signal OK!" % player.name)
		else:
			printerr("❌ Player '%s' MISSING 'skill_collected' signal!" % player.name)
			return
	else:
		# Retry...
		retry_count += 1
		if retry_count < MAX_RETRIES:
			var timer = Timer.new()
			timer.wait_time = PLAYER_RETRY_DELAY
			timer.one_shot = true
			timer.timeout.connect(func(): call_deferred("setup_player_connection"))
			get_parent().add_child(timer)
			timer.start()
			print("⏳ Player not ready, retrying in %.1fs..." % PLAYER_RETRY_DELAY)
		else:
			printerr("💥 MAX RETRIES: No player found after 5s!")
	
	# Setup slots regardless
	setup_slots()

func setup_slots():
	for i in range(slots.size()):
		slots[i].change_key = str(i + 1)
		if i < skills.size():
			slots[i].skill = skills[i]
			slots[i].skill.apply_to_button(slots[i])

# ✅ Helper: Find by class (backup)
func find_player_by_class() -> Player:
	for node in get_tree().root.find_children("*", "Player", true, false):
		return node as Player
	return null

# ✅ ENSURE this gets called (previous fixes)
func _on_skill_collected(skill_resource: Skill):  
	var skill_name = skill_resource.name
	var skill_level = skill_resource.level
	
	var stack_gain := randi_range(2, 5)
	
	SkillStackManager.add_stack(skill_resource, stack_gain)
	
	var text := "+%d stacks %s Lv%d" % [stack_gain, skill_name, skill_level]
	_show_error_text(text)
	
	# Update existing or new slot...
	for i in range(slots.size()):
		var slot = slots[i]
		if slot.skill and slot.skill.name == skill_name:
			slot.skill.level = skill_level
			slot.skill.apply_to_button(slot)
			SkillStackManager.set_skill_in_bar(i, skill_name)
			return
	
	for i in range(slots.size()):
		var slot = slots[i]
		if not slot.skill:
			slot.skill = skill_resource.duplicate()
			slot.skill.apply_to_button(slot)
			slot.disabled = false
			slot.cooldown.value = 0
			slot.time_label.text = ""
			slot.set_process(false)
			SkillStackManager.set_skill_in_bar(i, skill_name)
			return
	
	_show_error_text("⚠️ Skill bar full!")
# ✅ DEBUG: Stack refresh tracking
func refresh_from_stack() -> void:
	for i in range(slots.size()):
		var slot = slots[i]
		slot.skill = null
		slot.disabled = true
		slot.time_label.text = ""
		slot.set_process(false)
	
	var index := 0
	for skill_name in SkillStackManager.table:
		if index >= slots.size(): 
			break
		
		var skill_data = SkillStackManager.table[skill_name]
		if skill_data.stack <= 0: 
			continue
		
		var skill_resource = skill_data.skill_resource
		if skill_resource:
			slots[index].skill = skill_resource.duplicate()
			slots[index].skill.apply_to_button(slots[index])
			slots[index].disabled = false
			index += 1
		else:
			print("⚠️ NULL skill_resource for %s in stack" % skill_name)
	
	print("✅ REFRESH complete: %d slots filled" % index)

# SAVE/LOAD: Store skill name + level
func save_data() -> Array:
	var result := []
	for i in range(slots.size()):
		var slot = slots[i]
		if slot.skill:
			result.append({
				"name": slot.skill.name,
				"level": slot.skill.level,
				"slot": i
			})
			print("💾 SAVE slot %d: %s Lv%d" % [i, slot.skill.name, slot.skill.level])
		else:
			result.append(null)
	return result

# ✅ DEBUG: Load tracking
func load_data(data: Array) -> void:
	print("📂 LOADING skillbar: %d entries" % data.size())
	slots = get_children()
	if data.size() != slots.size(): 
		print("⚠️ Data size mismatch: expected %d, got %d" % [slots.size(), data.size()])
		return

	for i in range(slots.size()):
		var slot_data = data[i]
		if not slot_data: 
			print("📭 Slot %d: empty" % i)
			continue

		var skill_name = slot_data.name
		var skill_level = slot_data.get("level", 1)
		
		var skill_resource = SkillDatabase.get_skill_by_name(skill_name)
		if skill_resource:
			skill_resource.level = skill_level
			var instance = skill_resource.duplicate()
			slots[i].skill = instance
			slots[i].skill.apply_to_button(slots[i])
			slots[i].disabled = false
			slots[i].time_label.text = ""
			slots[i].set_process(false)
			print("📥 LOAD slot %d: %s Lv%d from DB" % [i, skill_name, skill_level])
		else:
			print("❌ LOAD FAIL slot %d: %s not found in DB" % [i, skill_name])

# ✅ DEBUG: Skillbar change events
func on_skillbar_changed(slot_index: int, skill_data: Dictionary):
	print("📡 SkillbarChanged(slot=%d, data=%s)" % [slot_index, skill_data])
	
	if slot_index < 0 or slot_index >= slots.size(): 
		print("❌ Invalid slot_index: %d" % slot_index)
		return
	
	var slot = slots[slot_index]
	var skill_name = skill_data.get("name", "")
	var skill_level = skill_data.get("level", 1)
	
	if skill_name == "":
		print("🗑️ CLEARING slot %d" % slot_index)
		slot.skill = null
		slot.disabled = true
		slot.time_label.text = ""
		slot.set_process(false)
		return
	
	var skill_resource = SkillDatabase.get_skill_by_name(skill_name)
	if skill_resource:
		skill_resource.level = skill_level
		slot.skill = skill_resource.duplicate()
		slot.skill.apply_to_button(slot)
		slot.disabled = false
		slot.cooldown.value = 0
		slot.time_label.text = ""
		slot.set_process(false)
		print("✅ UPDATED slot %d: %s Lv%d" % [slot_index, skill_name, skill_level])
	else:
		print("❌ DB MISS: %s not found for slot %d" % [skill_name, slot_index])

func _show_error_text(message: String) -> void:
	print("📢 UI ALERT: %s" % message)
	if not alert_label:
		printerr("ErrorLabel not found!")
		return
	
	alert_label.text = message
	alert_label.visible = true
	alert_label.modulate.a = 1.0
	
	var tween = create_tween()
	tween.tween_interval(ERROR_DISPLAY_TIME)
	tween.tween_property(alert_label, "modulate:a", 0.0, 0.3)
	tween.tween_callback(func(): alert_label.visible = false)
