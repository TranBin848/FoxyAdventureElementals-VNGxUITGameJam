extends HBoxContainer
class_name SkillBarSkillTree

var slots: Array = []

func _ready() -> void:
	slots = get_children()
	
	# Setup slot keys
	for i in range(slots.size()):
		slots[i].change_key = str(i + 1)
	
	# Connect to SkillTreeManager signals
	SkillTreeManager.skill_equipped.connect(_on_skill_equipped)
	SkillTreeManager.skill_unequipped.connect(_on_skill_unequipped)
	SkillTreeManager.skill_leveled_up.connect(_on_skill_leveled_up)
	
	# Initial sync from manager
	_sync_from_manager()

func _sync_from_manager() -> void:
	"""Load UI from SkillTreeManager state"""
	var skillbar = SkillTreeManager.get_skillbar()  # ✅ Correct function name
	
	for i in range(slots.size()):
		_clear_slot_visuals(slots[i])
		
		if i < skillbar.size() and skillbar[i]:
			var skill_name = skillbar[i]
			var skill_instance = SkillTreeManager.get_skill_resource(skill_name)
			
			if skill_instance:
				_set_slot(slots[i], skill_instance)

func _on_skill_equipped(slot_index: int, skill_name: String) -> void:
	"""React to skill being equipped"""
	if slot_index < 0 or slot_index >= slots.size():
		return
	
	var skill_instance = SkillTreeManager.get_skill_resource(skill_name)
	if skill_instance:
		_set_slot(slots[slot_index], skill_instance)

func _on_skill_unequipped(slot_index: int, _skill_name: String) -> void:
	"""React to skill being unequipped"""
	if slot_index < 0 or slot_index >= slots.size():
		return
	
	_clear_slot_visuals(slots[slot_index])

func _on_skill_leveled_up(skill_name: String, _new_level: int) -> void:
	"""Update visual if this skill is currently equipped"""
	for i in range(slots.size()):
		if slots[i].skill and slots[i].skill.name == skill_name:
			# Refresh with updated level
			var updated_skill = SkillTreeManager.get_skill_resource(skill_name)
			if updated_skill:
				_set_slot(slots[i], updated_skill)

func _set_slot(slot, skill_instance: Skill) -> void:
	"""Set skill in slot with visuals"""
	slot.skill = skill_instance
	skill_instance.apply_to_button(slot)
	slot.disabled = false
	slot.cooldown.value = 0
	slot.time_label.text = ""
	slot.set_process(false)

func _clear_slot_visuals(slot) -> void:
	"""Clear slot visuals"""
	slot.skill = null
	slot.texture_normal = null
	slot.disabled = true
	slot.time_label.text = ""
	slot.set_process(false)
