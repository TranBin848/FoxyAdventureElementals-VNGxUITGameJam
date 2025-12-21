extends HBoxContainer
class_name SkillBarSkillTree

var slots: Array
var skills: Array = [ThousandSwords, CometRain, Thunderbolt, Burrow]

func _ready() -> void:
	slots = get_children()
	
	# Gọi Singleton SkillTreeManager (bạn nhớ add vào Autoload và đặt tên là SkillTreeManager)
	load_ui_from_manager()
	
	SkillTreeManager.skillbar_changed.connect(on_skillbar_changed)

# Hàm này load lại toàn bộ UI dựa trên dữ liệu hiện tại của Manager
func load_ui_from_manager() -> void:
	var bar_data = SkillTreeManager.get_skill_bar_data()
	for i in range(slots.size()):
		# Cấu hình phím tắt (1, 2, 3...)
		slots[i].change_key = str(i + 1)
		
		# Reset slot trước
		_clear_slot_visuals(slots[i])

		if i < bar_data.size():
			var skill_name = bar_data[i]
			if skill_name:
				on_skillbar_changed(i, skill_name)

func on_skillbar_changed(slot_index: int, skill_name: String):
	if slot_index < 0 or slot_index >= slots.size():
		return

	var slot = slots[slot_index]
	
	# ----- CLEAR SLOT -----
	if skill_name == "" or skill_name == null:
		_clear_slot_visuals(slot)
		return
	
	# ----- SET SKILL -----
	# Lấy skill resource từ Manager (đã bao gồm đúng Level)
	var skill_instance = SkillTreeManager.get_skill_resource(skill_name)
	
	if skill_instance:
		slot.skill = skill_instance
		slot.skill.apply_to_button(slot)
		slot.disabled = false
		slot.cooldown.value = 0
		slot.time_label.text = ""
		slot.set_process(false)
	else:
		# Nếu skill có tên nhưng chưa unlock hoặc lỗi data
		_clear_slot_visuals(slot)

func _clear_slot_visuals(slot) -> void:
	slot.skill = null
	slot.texture_normal = null
	slot.disabled = true
	slot.time_label.text = ""
	slot.set_process(false)
