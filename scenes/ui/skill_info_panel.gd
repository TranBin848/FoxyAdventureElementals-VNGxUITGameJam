extends Panel
class_name SkillInfoPanel

const ERROR_DISPLAY_TIME: float = 2.0

@onready var title_label: Label = $Title
@onready var level_label: Label = $Level
@onready var stat_label: RichTextLabel = $Stat
@onready var stack_label: Label = $Stack
@onready var upgrade_btn: Button = $UpgradeButton
@onready var unlock_btn: Button = $UnlockButton
@onready var equip_button: Button = $EquipButton
@onready var video_player: VideoStreamPlayer = $VideoStreamPlayer
@onready var alert_label: Label = $"../NotiLabel"
@onready var skillbar: PanelContainer = $"../skillbar"

var current_button: SkillButtonNode
var current_skill_name: String = ""

func _ready() -> void:
	SkillTreeManager.stack_changed.connect(_on_stack_changed)

func show_skill(btn: SkillButtonNode):
	var sk = btn.skill
	if sk == null:
		return
	
	visible = true
	current_button = btn
	current_skill_name = sk.name
	
	# 🔥 USE SkillTreeManager data (not btn properties!)
	title_label.text = sk.name
	level_label.text = "Level: %d" % SkillTreeManager.get_level(sk.name)
	stack_label.text = "Stack: %d" % SkillTreeManager.get_skill_stack(sk.name)
	stat_label.text = get_stat_text(sk)
	
	_update_buttons()
	
	if btn.video_stream:
		video_player.stream = btn.video_stream
		video_player.play()
	else:
		video_player.stream = null
		video_player.stop()

func get_stat_text(sk: Skill) -> String:
	var lines: Array[String] = []
		
	# --- elemental_type Color using ENUM names directly ---
	var color_map := {
		ElementsEnum.Elements.FIRE: "[color=#ff4a4a]",   
		ElementsEnum.Elements.WATER: "[color=#4aaaff]",  
		ElementsEnum.Elements.EARTH: "[color=#c29a5b]",  
		ElementsEnum.Elements.WOOD: "[color=#4caf50]",   
		ElementsEnum.Elements.METAL: "[color=#d0d0d0]",  
	}

	var elem_color := "[color=white]"
	if color_map.has(sk.elemental_type):
		elem_color = color_map[sk.elemental_type]

	# --- Header line with ENUM name ---
	var elem_name = ElementsEnum.Elements.keys()[sk.elemental_type]
	var elemental_type_text := "%s%s[/color]" % [elem_color, elem_name]
	lines.append("Stats:                         " + elemental_type_text)
	lines.append("Damage: %d" % sk.damage)
	lines.append("Cooldown: %.2f s" % sk.cooldown)
	lines.append("Mana: %d" % sk.mana)
	lines.append("Duration: %.2f s" % sk.duration)
	
	# --- Translated Skill Types ---
	var type_map := {
		"single_shot": "Single Shot",
		"multi_shot": "Multi Shot", 
		"radial": "Radial Burst",
		"area": "Area Effect",
		"buff": "Self Buff"
	}
	var skill_type_text = type_map.get(sk.type, sk.type)
	lines.append("Skill Type: %s" % skill_type_text)
	
	return "\n\n".join(lines)

func _update_buttons():
	if current_button == null:
		return
		
	var skill_name = current_skill_name
	var is_unlocked = SkillTreeManager.get_unlocked(skill_name)
	var level = SkillTreeManager.get_level(skill_name)
	var stack = SkillTreeManager.get_skill_stack(skill_name)
	
	# ----- UNLOCK BUTTON -----
	if is_unlocked:
		unlock_btn.disabled = true
		unlock_btn.text = "UNLOCKED"
	else:
		unlock_btn.disabled = false
		unlock_btn.text = "UNLOCK"
	
	# ----- UPGRADE BUTTON -----
	if not is_unlocked or level >= 3:
		upgrade_btn.disabled = true
		upgrade_btn.text = "MAX LEVEL"
	else:
		upgrade_btn.disabled = false
		upgrade_btn.text = "UPGRADE"
	
	# ----- EQUIP BUTTON -----
	var index = SkillTreeManager.find_skill_in_bar(skill_name)
	if index != -1:
		equip_button.text = "UNEQUIP (Slot %d)" % (index + 1)
	else:
		equip_button.text = "EQUIP"

func _on_unlock_button_pressed() -> void:
	if current_skill_name == "":
		return
		
	var skill_name = current_skill_name
	if SkillTreeManager.get_unlocked(skill_name):
		return

	var require_stack = 5  # Configurable
	if SkillTreeManager.get_skill_stack(skill_name) >= require_stack:
		var skill_res = SkillDatabase.get_skill_by_name(skill_name)
		if skill_res:
			SkillTreeManager.unlock_skill_with_cost(skill_name, require_stack)
			_show_error_text("✅ Unlocked %s!" % skill_name)
	else:
		_show_error_text("❌ Need %d stacks (have %d)" % [require_stack, SkillTreeManager.get_skill_stack(skill_name)])
	
	_update_buttons()

func _on_upgrade_button_pressed() -> void:
	if current_skill_name == "":
		return
		
	var skill_name = current_skill_name
	if not SkillTreeManager.get_unlocked(skill_name):
		return
	
	var level = SkillTreeManager.get_level(skill_name)
	var require_stack = 10  # Configurable
	if SkillTreeManager.get_skill_stack(skill_name) >= require_stack:
		var skill_res = SkillDatabase.get_skill_by_name(skill_name)
		if skill_res:
			SkillTreeManager.remove_stack(skill_res, require_stack)
			SkillTreeManager.level_up_skill(skill_name)
			_show_error_text("✅ Upgraded to Lv%d!" % (level + 1))
	else:
		_show_error_text("❌ Need %d stacks" % require_stack)
	
	_update_buttons()

func _on_stack_changed(skill_name: String, new_stack: int):
	# Only update if this panel shows that skill
	if current_skill_name == skill_name:
		stack_label.text = "Stack: %d" % new_stack

func _on_equip_button_pressed() -> void:
	if current_skill_name == "":
		return

	var skill_name = current_skill_name
	var index = SkillTreeManager.find_skill_in_bar(skill_name)

	# ----- UNEQUIP -----
	if index != -1:
		SkillTreeManager.unequip_skill(skill_name)
		_show_error_text("🗑️ Unequipped from slot %d" % (index + 1))
		_update_buttons()
		return

	# ----- EQUIP -----
	if not SkillTreeManager.get_unlocked(skill_name):
		_show_error_text("❌ Skill not unlocked!")
		return
	
	var bar = SkillTreeManager.get_skill_bar_data()
	for i in range(bar.size()):
		if bar[i] == null:
			SkillTreeManager.equip_skill(i, skill_name)
			_show_error_text("✅ Equipped to slot %d!" % (i + 1))
			_update_buttons()
			return
	
	_show_error_text("❌ Skill bar is full!")

func _show_error_text(message: String) -> void:
	if alert_label == null:
		printerr("Label thông báo chưa được tìm thấy trong Scene Tree!")
		return
	
	alert_label.text = message
	alert_label.visible = true
	alert_label.modulate = Color(1, 1, 1, 1)
	
	var tween = create_tween()
	tween.tween_interval(ERROR_DISPLAY_TIME)
	tween.tween_property(alert_label, "modulate", Color(1, 1, 1, 0), 0.3)
	tween.tween_callback(func(): alert_label.visible = false)

func _on_close_button_pressed():
	visible = false
