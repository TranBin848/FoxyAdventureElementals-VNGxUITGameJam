extends HBoxContainer
class_name SkillBar

var slots: Array = []
var _alert_label: Label = null

func _ready() -> void:
	slots = get_children()
	_alert_label = get_tree().root.find_child("ErrorLabel", true, false)
	
	# Setup slots
	for i in range(slots.size()):
		slots[i].change_key = str(i + 1)
	
	# Connect to manager (single source of truth)
	SkillTreeManager.skill_equipped.connect(_on_skill_equipped)
	SkillTreeManager.skill_unequipped.connect(_on_skill_unequipped)
	SkillTreeManager.stack_changed.connect(_on_stack_changed)
	
	# Connect to player events
	call_deferred("_connect_player")
	
	# Initial sync
	_sync_from_manager()

func _connect_player() -> void:
	var player = get_tree().get_first_node_in_group("player")
	if player and player.has_signal("skill_collected"):
		player.skill_collected.connect(_on_player_collected_skill)

# ✅ REFACTORED: Only display notification, don't modify state
func _on_player_collected_skill(skill_resource: Skill, stack_amount: int) -> void:
	"""Display collection notification - state is already updated by manager"""
	_show_collection_notification(skill_resource.name, stack_amount)

func _on_skill_equipped(slot_index: int, skill_name: String) -> void:
	"""React to state change from manager"""
	if slot_index < 0 or slot_index >= slots.size():
		return
	
	var skill = SkillTreeManager.get_skill_resource(skill_name)
	if skill:
		_update_slot(slot_index, skill)

func _on_skill_unequipped(slot_index: int, _skill_name: String) -> void:
	"""React to state change from manager"""
	if slot_index < 0 or slot_index >= slots.size():
		return
	
	_clear_slot(slot_index)

func _on_stack_changed(skill_name: String, _amount: int) -> void:
	"""Update stack display if this skill is equipped"""
	for i in range(slots.size()):
		if slots[i].skill and slots[i].skill.name == skill_name:
			# Refresh display
			_update_slot(i, slots[i].skill)

func _sync_from_manager() -> void:
	"""Sync entire bar from manager state"""
	var skillbar = SkillTreeManager.get_skillbar()
	for i in range(slots.size()):
		if i < skillbar.size() and skillbar[i]:
			var skill = SkillTreeManager.get_skill_resource(skillbar[i])
			if skill:
				_update_slot(i, skill)
		else:
			_clear_slot(i)

func _update_slot(index: int, skill: Skill) -> void:
	var slot = slots[index]
	slot.skill = skill
	skill.apply_to_button(slot)
	slot.disabled = false
	slot.cooldown.value = 0
	slot.time_label.text = ""

func _clear_slot(index: int) -> void:
	var slot = slots[index]
	slot.skill = null
	slot.texture_normal = null
	slot.disabled = true
	slot.time_label.text = ""

func _show_collection_notification(skill_name: String, amount: int) -> void:
	"""Show visual feedback for collected skill"""
	if not _alert_label:
		return
	
	_alert_label.text = "+%d %s" % [amount, skill_name]
	_alert_label.visible = true
	_alert_label.modulate.a = 1.0
	
	var tween = create_tween()
	tween.tween_interval(2.0)
	tween.tween_property(_alert_label, "modulate:a", 0.0, 0.3)
	tween.tween_callback(func(): _alert_label.visible = false)
