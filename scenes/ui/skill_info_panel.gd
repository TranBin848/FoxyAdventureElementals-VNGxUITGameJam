extends Panel
class_name SkillInfoPanel

const ERROR_DISPLAY_TIME: float = 2.0

@onready var title_label: Label = $Title
@onready var level_label: Label = $Level
@onready var stat_label: RichTextLabel = $Stat
@onready var stack_label: Label = $Stack
@onready var upgrade_btn: Button = $UpgradeButton
@onready var unlock_btn: Button = $UnlockButton
@onready var video_player: VideoStreamPlayer = $VideoStreamPlayer
@onready var alert_label: Label = $"../ErrorLabel"

var current_button: SkillButtonNode

func _ready() -> void:
	SkillStackManager.stack_changed.connect(_on_stack_changed)

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
		
	# --- Element Color ---
	var color_map := {
		"Fire": "[color=#ff4a4a]",   # đỏ
		"Water": "[color=#4aaaff]",  # xanh nước
		"Earth": "[color=#c29a5b]",  # nâu đất
		"Wood": "[color=#4caf50]",   # xanh lá
		"Metal": "[color=#d0d0d0]",  # bạc
	}

	var elem_color := "[color=white]"
	if color_map.has(sk.element):
		elem_color = color_map[sk.element]

	# --- Header line ---
	var element_text := "%s%s[/color]" % [elem_color, sk.element]
	lines.append("Stats:                         " + element_text)

	# --- Các stats ---
	if sk.damage > 0:
		lines.append("Damage: %d" % sk.damage)

	if sk.cooldown > 0:
		lines.append("Cooldown: %.2f s" % sk.cooldown)

	if sk.mana > 0:
		lines.append("Mana: %d" % sk.mana)

	if sk.speed > 0:
		lines.append("Speed: %d" % sk.speed)

	if sk.duration > 0:
		lines.append("Duration: %.2f s" % sk.duration)

	if sk.type != "":
		lines.append("Skill Type: %s" % sk.type)
	
	# --- ghép dòng + spacing giả ---
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
	if not btn.unlocked:
		# Chưa mở khóa → không được nâng cấp
		upgrade_btn.disabled = true
	else:
		# Đã mở khóa → check đủ điều kiện nâng cấp chưa
		if btn.level < 3:
			upgrade_btn.disabled = false
		else:
			upgrade_btn.disabled = true


func _on_unlock_button_pressed() -> void:
	var btn = current_button
	if btn.unlocked:
		return

	if btn.stack >= btn.require_stack_unlock:
		SkillStackManager.remove_stack(btn.skill.name, btn.require_stack_upgrade)
		#SkillStackManager.set_level(btn.skill.name, btn.level + 1)
		SkillStackManager.set_unlocked(btn.skill.name)
		btn.unlocked = true
		btn.disabled = false
		_show_error_text("Unlock successfully.")
		#if btn.level == 3:
			#_unlock_children(btn)
		
	_update_buttons()


func _on_upgrade_button_pressed() -> void:
	var btn = current_button

	if not btn.unlocked:
		return

	if btn.stack >= btn.require_stack_upgrade and btn.level < 3:
		SkillStackManager.remove_stack(btn.skill.name, btn.require_stack_upgrade)
		SkillStackManager.set_level(btn.skill.name, btn.level + 1)
		#if btn.level == 3:
			#_unlock_children(btn)
		_show_error_text("Upgrade successfully.")
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
