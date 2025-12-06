extends HBoxContainer

var slots: Array
var skills: Array = []
var available_skills: Array = []

func _ready() -> void:
	slots = get_children()

	refresh_from_stack()
	
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
			
			#Kiểm tra xem đã đạt stack tối đa chưa
			if existing_skill.current_stack < existing_skill.max_stack:
				#Tăng cấp/stack
				existing_skill.current_stack += 1
				print(existing_skill.current_stack)
				#Tùy chọn: Gọi hàm nâng cấp để tăng damage, giảm cooldown, v.v.
				#existing_skill.apply_upgrade() 
				
				#Cập nhật lại UI (cooldown bar, vv) nếu cần
				existing_skill.apply_to_button(slot)
				
				
				
				print("✨ Skill '%s' UPGRADED to level %d!" % [existing_skill.name, existing_skill.current_stack])
				return # Thoát vì đã nâng cấp thành công
			else:
				print("⚠️ Skill '%s' đã đạt cấp tối đa (%d)." % [existing_skill.name, existing_skill.max_stack])
				#Tùy chọn: Có thể cho Player nhặt một vật phẩm khác (ví dụ: tiền)
				return

	#2. TÌM SLOT TRỐNG (NEW SKILL)
	for slot in slots:
		if slot.skill == null:
			#Gán Skill vào slot trống (Skill mới bắt đầu ở stack 1)
			slot.skill = new_skill_instance
			slot.skill.current_stack = 1 
			
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
	if SkillStackManager.stack_table.is_empty():
		return

	for slot in slots:
		slot.skill = null
		slot.disabled = true
		slot.time_label.text = ""
		slot.set_process(false)

	var index := 0

	for skill_name in SkillStackManager.stack_table.keys():
		if index >= slots.size():
			break

		# Tạo instance skill từ tên
		var db = SkillDatabase.new()
		var skill_resource = db.get_skill_by_name(skill_name)
		if skill_resource == null:
			continue

		var instance = skill_resource.new()
		instance.current_stack = SkillStackManager.stack_table[skill_name]

		slots[index].skill = instance
		instance.apply_to_button(slots[index])

		slots[index].disabled = false
		index += 1
