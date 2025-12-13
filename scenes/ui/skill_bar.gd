extends HBoxContainer
class_name SkillBar

var slots: Array
var skills: Array = []
#var available_skills: Array = []

func _ready() -> void:
	#refresh_from_stack()
	slots = get_children()
	
	load_data(SkillStackManager.get_skill_bar_data())
	
	var player = get_tree().get_first_node_in_group("player")
	for i in get_child_count():
		slots[i].change_key = str(i + 1)
		if i <= skills.size() - 1:
			slots[i].skill = skills[i].new()
			slots[i].skill.apply_to_button(slots[i])
	if player:
		# Lắng nghe tín hiệu nhặt Skill từ Player
		player.skill_collected.connect(_on_skill_collected)
	
	SkillStackManager.skillbar_changed.connect(on_skillbar_changed)
	
func _on_skill_collected(skill_resource_class: Script):
	var new_skill_instance = skill_resource_class.new()
	var skill_name = new_skill_instance.name
	
	SkillStackManager.add_stack(new_skill_instance.name, 1)
	
	for i in range(slots.size()):
		var slot = slots[i]
		if slot.skill != null and slot.skill.name == skill_name:
			slot.skill.apply_to_button(slot)

			# đảm bảo manager biết skill này đang ở slot nào
			SkillStackManager.set_skill_in_bar(i, skill_name)
			return
		
	# 2. SKILL MỚI → nhét vào slot trống
	for i in range(slots.size()):
		var slot = slots[i]
		if slot.skill == null:
			slot.skill = new_skill_instance

			slot.skill.apply_to_button(slot)
			slot.disabled = false
			slot.cooldown.value = 0
			slot.time_label.text = ""
			slot.set_process(false)

			# 🔴 QUAN TRỌNG: cập nhật manager
			SkillStackManager.set_skill_in_bar(i, skill_name)

			print("✅ New skill '%s' added to slot %d!" % [skill_name, i])
			return

	print("⚠️ Không có slot trống để chứa Skill mới!")

func refresh_from_stack() -> void:
	if SkillStackManager.table.is_empty():
		return

	for slot in slots:
		slot.skill = null
		slot.disabled = true
		slot.time_label.text = ""
		slot.set_process(false)

	var index := 0

	for skill_name in SkillStackManager.table.keys():
		if index >= slots.size():
			break

		# Tạo instance skill từ tên
		var db = SkillDatabase.new()
		var skill_resource = db.get_skill_by_name(skill_name)
		if skill_resource == null:
			continue

		var instance = skill_resource.new()
		
		var skill_current_stack = SkillStackManager.get_stack(skill_name)
		
		if (skill_current_stack > 0):
			slots[index].skill = instance
			instance.apply_to_button(slots[index])

			slots[index].disabled = false
			index += 1

####SAVE LOAD SYSTEM
func save_data() -> Array:
	var result := []
	for slot in slots:
		if slot.skill:
			result.append(slot.skill.name) # lưu theo tên skill
		else:
			result.append(null)
	return result
	
func load_data(data: Array) -> void:
	slots = get_children()
	if data.size() != slots.size():
		return

	for i in range(slots.size()):
		var skill_name = data[i]
		if skill_name == null:
			continue

		# load skill instance
		var db = SkillDatabase.new()
		var skill_script = db.get_skill_by_name(skill_name)
		if skill_script:
			var instance = skill_script.new()
			slots[i].skill = instance
			slots[i].skill.apply_to_button(slots[i])
			slots[i].disabled = false
			slots[i].time_label.text = ""
			slots[i].set_process(false)

func on_skillbar_changed(slot_index: int, skill_name: String):
	if slot_index < 0 or slot_index >= slots.size():
		return

	var slot = slots[slot_index]
	
	# ----- CLEAR SLOT -----
	if skill_name == "":
		slot.skill = null
		slot.texture_normal = null
		slot.update_stack_ui() 
		slot.disabled = true
		slot.time_label.text = ""
		slot.set_process(false)
		return
	
	# ----- SET SKILL -----
	if slot.skill != null:
		return
	var db = SkillDatabase.new()
	var skill_script = db.get_skill_by_name(skill_name)
	if skill_script == null:
		return

	var instance = skill_script.new()
	slot.skill = instance

	instance.apply_to_button(slot)
	slot.disabled = false
	slot.cooldown.value = 0
	slot.time_label.text = ""
	slot.set_process(false)
	
