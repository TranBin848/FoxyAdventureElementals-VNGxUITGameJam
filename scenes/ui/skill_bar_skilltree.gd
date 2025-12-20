extends HBoxContainer
class_name SkillBarSkillTree

var slots: Array
var skills: Array = [ThousandSwords, WaterSpike, StunShot, ToxicBreath]
#var available_skills: Array = []

func _ready() -> void:
	#refresh_from_stack()
	slots = get_children()
	
	load_data(SkillStackManager.get_skill_bar_data())
	
	for i in get_child_count():
		slots[i].change_key = str(i + 1)
		if i <= skills.size() - 1:
			slots[i].skill = skills[i].new()
			slots[i].skill.apply_to_button(slots[i])

	SkillStackManager.skillbar_changed.connect(on_skillbar_changed)
	


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
	
