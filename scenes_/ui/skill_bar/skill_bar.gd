extends HBoxContainer
class_name SkillBar

var slots: Array = []
var _alert_label: Label = null

func _ready() -> void:
	slots = get_children()
	_alert_label = get_tree().root.find_child("ErrorLabel", true, false)
	
	# Setup UI visuals (Keys)
	for i in range(slots.size()):
		slots[i].change_key = str(i + 1)
	
	# --- CONNECT TO MANAGER ---
	
	# 1. Runtime Updates (Granular)
	# These handle specific events while the game is running (efficient)
	SkillTreeManager.skill_equipped.connect(_on_skill_equipped)
	SkillTreeManager.skill_unequipped.connect(_on_skill_unequipped)
	SkillTreeManager.stack_changed.connect(_on_stack_changed)
	
	# 2. Full State Sync (Loading)
	# This handles Save/Load or full resets.
	SkillTreeManager.state_changed.connect(_on_full_state_update)
	
	# 3. Notification Logic (Visuals only)
	call_deferred("_connect_player_notifications")
	
	# 4. Initial Sync
	# Just in case Manager loaded before this _ready fired
	_sync_from_manager()

func _on_full_state_update(_state_dict: Dictionary) -> void:
	"""Called when Manager loads a save file or resets"""
	_sync_from_manager()

func _sync_from_manager() -> void:
	"""Reads the current source of truth and forces the UI to match it exactly"""
	var manager_bar = SkillTreeManager.get_skillbar()
	
	for i in range(slots.size()):
		# Safety check: does the manager have a slot for this UI element?
		if i < manager_bar.size() and manager_bar[i] != null:
			var skill_name = manager_bar[i]
			var skill_res = SkillTreeManager.get_skill_resource(skill_name)
			
			if skill_res:
				_update_slot(i, skill_res)
			else:
				# Edge case: Manager has a name, but resource generation failed (e.g. locked)
				_clear_slot(i)
		else:
			_clear_slot(i)

# --- Runtime Handlers (Optimized for single updates) ---

func _on_skill_equipped(slot_index: int, skill_name: String) -> void:
	if slot_index < 0 or slot_index >= slots.size(): return
	var skill = SkillTreeManager.get_skill_resource(skill_name)
	if skill: _update_slot(slot_index, skill)

func _on_skill_unequipped(slot_index: int, _skill_name: String) -> void:
	if slot_index < 0 or slot_index >= slots.size(): return
	_clear_slot(slot_index)

func _on_stack_changed(skill_name: String, _amount: int) -> void:
	# Find which slot holds this skill and refresh it
	for i in range(slots.size()):
		if slots[i].skill and slots[i].skill.name == skill_name:
			# Re-fetching the resource ensures we get updated stack counts/levels
			var skill = SkillTreeManager.get_skill_resource(skill_name)
			if skill: _update_slot(i, skill)

# --- Visual Logic ---

func _update_slot(index: int, skill: Skill) -> void:
	var slot = slots[index]
	slot.skill = skill
	skill.apply_to_button(slot) # Assuming this sets icon, stack count text, etc.
	slot.disabled = false
	slot.cooldown.value = 0
	slot.time_label.text = ""

func _clear_slot(index: int) -> void:
	var slot = slots[index]
	slot.skill = null
	slot.texture_normal = null # Clear icon
	slot.disabled = true
	slot.time_label.text = ""

# --- Player Notification (Optional Visuals) ---

func _connect_player_notifications() -> void:
	var player = get_tree().root.find_child("Player", true, false)
	if player and player.has_signal("skill_collected"):
		player.skill_collected.connect(_show_collection_notification)

func _show_collection_notification(skill_resource: Skill, stack_amount: int) -> void:
	# This is PURELY visual. Logic is handled by Manager.
	if not _alert_label: return
	
	_alert_label.text = "+ %d stacks %s" % [stack_amount, skill_resource.name]
	_alert_label.visible = true
	_alert_label.modulate.a = 1.0
	
	var tween = create_tween()
	tween.tween_interval(2.0)
	tween.tween_property(_alert_label, "modulate:a", 0.0, 0.3)
	tween.tween_callback(func(): _alert_label.visible = false)
