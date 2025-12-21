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

func _ready() -> void:
	SkillTreeManager.stack_changed.connect(_on_stack_changed)

func show_skill(btn: SkillButtonNode):
	var sk = btn.skill
	if sk == null:
		return
	
	visible = true
	title_label.text = sk.name
	level_label.text = "Level: %d" % btn.level
	stack_label.text = "Stack: %d" % btn.stack
	stat_label.text = get_stat_text(sk)
	
	current_button = btn
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
	var btn = current_button

	# ----- UNLOCK -----
	if btn.unlocked:
		unlock_btn.disabled = true
		btn.panel.show_behind_parent = true	
	else:
		unlock_btn.disabled = false
	# ----- UPGRADE -----
	if not btn.unlocked or btn.level >= 3:
		# Chưa mở khóa → không được nâng cấp
		upgrade_btn.disabled = true
	else:
		upgrade_btn.disabled = false
	
	var index = SkillTreeManager.find_skill_in_bar(btn.skill.name)
	if index != -1:
		equip_button.text = "UNEQUIP"
	else:
		equip_button.text = "EQUIP"

func _on_unlock_button_pressed() -> void:
	var btn = current_button
	if btn.unlocked:
		return

	if btn.stack >= btn.require_stack_unlock:
		SkillTreeManager.remove_stack(btn.skill.name, btn.require_stack_upgrade)
		#SkillTreeManager.set_level(btn.skill.name, btn.level + 1)
		SkillTreeManager.set_unlocked(btn.skill.name)
		btn.unlocked = true
		btn.disabled = false
		_show_error_text("Unlock successfully.")
		#if btn.level == 3:
			#_unlock_children(btn)
	else:
		_show_error_text("Not enough stacks.")	
	_update_buttons()


func _on_upgrade_button_pressed() -> void:
	var btn = current_button

	if not btn.unlocked:
		return

	if btn.stack >= btn.require_stack_upgrade and btn.level < 3:
		SkillTreeManager.remove_stack(btn.skill.name, btn.require_stack_upgrade)
		SkillTreeManager.set_level(btn.skill.name, btn.level + 1)
		#if btn.level == 3:
			#_unlock_children(btn)
		_show_error_text("Upgrade successfully.")
	
	else:
		_show_error_text("Not enough stacks.")	
	
	_update_buttons()



func _unlock_children(parent: SkillButtonNode) -> void:
	for child in parent.children:
		# Chỉ mở khóa nếu chưa mở
		if not child.unlocked:
			child.unlocked = true
			child.disabled = false  # Cho bấm luôn nếu muốn
			_highlight_line(child)

func _highlight_line(child: SkillButtonNode) -> void:
	# Line nằm ở child
	var line := child.line_2d
	line.modulate = Color(1,1,0.3,1.0).lerp(Color(1,1,1,1), 0.5)
	line.width = 4

func _on_stack_changed(skill_name: String, new_stack: int):
	stack_label.text = "Stack: %d" % new_stack

func _show_error_text(message: String) -> void:
	if alert_label == null:
		printerr("Label thông báo chưa được tìm thấy trong Scene Tree!")
		return
	
	alert_label.text = message
	alert_label.visible = true
	alert_label.modulate = Color(1, 1, 1, 1) # Đảm bảo không trong suốt ban đầu
	
	# Khởi tạo Tween để làm hiệu ứng Fade Out
	var tween = create_tween()
	
	# Chờ một chút
	tween.tween_interval(ERROR_DISPLAY_TIME)
	
	# Fade Out và ẩn Label
	tween.tween_property(alert_label, "modulate", Color(1, 1, 1, 0), 0.3)
	
	# Sau khi fade xong, đảm bảo label.visible = false
	tween.tween_callback(Callable(alert_label, "set_visible").bind(false))


func _on_equip_button_pressed() -> void:
	if current_button == null:
		return

	var skill_name = current_button.skill.name
	var index = SkillTreeManager.find_skill_in_bar(skill_name)

	# ----- ĐÃ EQUIP → UNEQUIP -----
	if index != -1:
		SkillTreeManager.unequip_skill(skill_name)
		_show_error_text("Unequipped.")
		_update_buttons()
		return

	# ----- CHƯA EQUIP → EQUIP -----
	var skill_unlock = SkillTreeManager.get_unlocked(skill_name)
	if skill_unlock:
		var bar = SkillTreeManager.get_skill_bar_data()
		for i in range(bar.size()):
			if bar[i] == null:
				SkillTreeManager.equip_skill(i, skill_name)
				_show_error_text("Equipped to slot %d." % (i + 1))
				_update_buttons()
				return
	else:
		_show_error_text("Skill not unlocked.")
		return
	_show_error_text("Skill bar is full!")


func _on_close_button_pressed():
	visible = false
