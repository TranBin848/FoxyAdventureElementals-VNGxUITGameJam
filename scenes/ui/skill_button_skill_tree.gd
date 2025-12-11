extends TextureButton
class_name SkillButtonNode

@onready var panel: Panel = $Panel
@onready var level_label: Label = $MarginContainer/LevelLabel
@onready var stack_label: Label = $MarginContainer/StackLabel
@onready var line_2d: Line2D = $Line2D

@export var skill: Skill
@export var require_stack_unlock := 1
@export var require_stack_upgrade := 1

@export var video_stream: VideoStream = null

var unlocked: bool = false
var children: Array[SkillButtonNode] = []

signal skill_selected(skill)

func _ready() -> void:
	if get_parent() is SkillButtonNode:
		var parent_btn: SkillButtonNode = get_parent()
		parent_btn.children.append(self)
		
		line_2d.add_point(global_position + size/2 - Vector2(4,4))
		line_2d.add_point(get_parent().global_position + size/2 - Vector2(4,4))
		
	SkillStackManager.stack_changed.connect(_on_stack_changed)
	SkillStackManager.level_changed.connect(_on_level_changed)
	
var level : int = 0:
	set(value):
		level = value
		level_label.text = str(level) + "/3"

var stack: int = 0

func _on_pressed() -> void:
	emit_signal("skill_selected", self)

func set_skill():
	if skill == null:
		return

	# Cập nhật texture
	if skill.texture:
		texture_normal = skill.texture
	
	level = SkillStackManager.get_level(skill.name)
	stack = SkillStackManager.get_stack(skill.name)
	
	if level > 1:
		unlocked = true
		disabled = false
	
	stack_label.text = str(stack)
	
	# Đặt tooltip hoặc tên nếu cần
	tooltip_text = skill.name
	
	#if not unlocked:
		#disabled = true
		#modulate = Color(0.5,0.5,0.5)

func _on_stack_changed(skill_name: String, new_stack: int):
	if skill == null or skill_name != skill.name:
		return

	stack = new_stack
	stack_label.text = str(stack)

	## Nếu chưa unlock → check unlock bằng stack
	#if not unlocked and stack >= require_stack_unlock:
		#unlocked = true
		#disabled = false
		#modulate = Color(1,1,1)

# ───────────────────────────────────────────
# CẬP NHẬT LEVEL
# ───────────────────────────────────────────
func _on_level_changed(skill_name: String, new_level: int):
	if skill == null or skill_name != skill.name:
		return

	level = new_level  # setter tự update UI

	# Nếu đã đạt cấp 3 → mở khóa children
	if level >= 3:
		_unlock_children()
	
func _unlock_children():
	for child in children:
		if not child.unlocked:
			child.unlocked = true
			child.disabled = false
			child.modulate = Color(1,1,1)
			_highlight_line(child)

func _highlight_line(child: SkillButtonNode):
	var line = child.line_2d
	line.default_color = Color(1,1,0.3)
	line.width = 4
