extends TextureButton
class_name SkillButtonNode

@onready var panel: Panel = $Panel
@onready var level_label: Label = $MarginContainer/LevelLabel
@onready var stack_label: Label = $MarginContainer/StackLabel
@onready var line_2d: Line2D = $Line2D

@export var skill: Skill
@export var require_stack_unlock := 3
@export var require_stack_upgrade := 3

@export var video_stream: VideoStream = null

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
	#SkillStackManager.level_changed.connect(_on_unlocked_changed)
	
var level : int = 0:
	set(value):
		level = value
		level_label.text = str(level) + "/3"

var stack: int = 0

var unlocked: bool = false

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
	
	unlocked = SkillStackManager.get_unlocked(skill.name)
	
	if unlocked:
		disabled = false
		panel.show_behind_parent = true	
		
	stack_label.text = str(stack)
	
	# Đặt tooltip hoặc tên nếu cần
	tooltip_text = skill.name
	
	for child in children:
		var skillchildunlocked = SkillStackManager.get_unlocked(child.skill.name)
		if skillchildunlocked:
			_highlight_line(child)
			
func _on_stack_changed(skill_name: String, new_stack: int):
	if skill == null or skill_name != skill.name:
		return

	stack = new_stack
	stack_label.text = str(stack)

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
		var skillchildunlocked = SkillStackManager.get_unlocked(child.skill.name)
		if not skillchildunlocked:
			#SkillStackManager.set_unlocked(child.skill.name)
			#child.unlocked = true
			child.disabled = false
			child.panel.show_behind_parent = true	
			_highlight_line(child)
	
func _highlight_line(child: SkillButtonNode):
	var line = child.line_2d
	line.default_color = Color(1,1,0.3)
	line.width = 4
