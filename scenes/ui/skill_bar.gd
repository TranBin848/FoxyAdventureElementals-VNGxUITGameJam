extends HBoxContainer
class_name SkillBar

var slots: Array
var skills: Array = []
var available_skills: Array = []

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

func _on_skill_collected(skill_resource_class: Script):
	var new_skill_instance = skill_resource_class.new()
	SkillStackManager.add_stack(new_skill_instance.name, 1)
	
	#1. KIỂM TRA NÂNG CẤP (UPGRADE)
	for slot in slots:
		if slot.skill != null and slot.skill.name == new_skill_instance.name:
			var existing_skill = slot.skill
			existing_skill.apply_to_button(slot)
			return # Thoát vì đã nâng cấp thành công
		
	#2. TÌM SLOT TRỐNG (NEW SKILL)
	for slot in slots:
		if slot.skill == null:
			#Gán Skill vào slot trống (Skill mới bắt đầu ở stack 1)
			slot.skill = new_skill_instance
			
			#Cập nhật UI
			slot.skill.apply_to_button(slot)
			slot.disabled = false 
			slot.cooldown.value = 0
			slot.time_label.text = ""
			slot.set_process(false)
			
			print("✅ New skill '%s' added to slot!" % slot.skill.name)
			return # Thoát sau khi thêm skill mới
			
	
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
