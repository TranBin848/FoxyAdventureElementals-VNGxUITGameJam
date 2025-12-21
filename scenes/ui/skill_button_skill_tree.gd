extends TextureButton
class_name SkillButtonNode

@onready var panel: Panel = $Panel
@onready var level_label: Label = $MarginContainer/LevelLabel
@onready var stack_label: Label = $MarginContainer/StackLabel
@onready var line_2d: Line2D = $Line2D

@export var skill: Skill
@export var require_stack_unlock := 5
@export var require_stack_upgrade := 10

@export var video_stream: VideoStream = null

var children: Array[SkillButtonNode] = []

# Line colors
const NORMAL_COLOR: Color = Color(0.5, 0.5, 0.5, 0.7)    # Gray (locked)
const UNLOCKED_COLOR: Color = Color(1, 1, 0.3, 1.0)       # Gold (unlocked)
const PARENT_COLOR: Color = Color(0.8, 0.8, 0.2, 1.0)     # Darker gold (parent)

signal skill_selected(skill)

func _ready() -> void:
	if get_parent() is SkillButtonNode:
		var parent_btn: SkillButtonNode = get_parent()
		parent_btn.children.append(self)
		
		line_2d.add_point(global_position + size/2 - Vector2(4,4))
		line_2d.add_point(get_parent().global_position + size/2 - Vector2(4,4))
		line_2d.default_color = NORMAL_COLOR  # Default locked color
		
	SkillStackManager.stack_changed.connect(_on_stack_changed)
	SkillStackManager.level_changed.connect(_on_level_changed)
	
	# Set initial line color
	_update_line_color()

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

	if skill.texture_path:
		texture_normal = load(skill.texture_path)
	
	level = SkillStackManager.get_level(skill.name)
	stack = SkillStackManager.get_stack(skill.name)
	unlocked = SkillStackManager.get_unlocked(skill.name)
	
	if unlocked:
		disabled = false
		panel.show_behind_parent = true	
		
	stack_label.text = str(stack)
	tooltip_text = skill.name
	
	_update_line_color()
	
	for child in children:
		var skillchildunlocked = SkillStackManager.get_unlocked(child.skill.name)
		if skillchildunlocked:
			child._highlight_line()

func _update_line_color():
	if unlocked:
		line_2d.default_color = UNLOCKED_COLOR
		line_2d.width = 4
	else:
		line_2d.default_color = NORMAL_COLOR
		line_2d.width = 2

func _on_stack_changed(skill_name: String, new_stack: int):
	if skill == null or skill_name != skill.name:
		return

	stack = new_stack
	stack_label.text = str(stack)

func _on_level_changed(skill_name: String, new_level: int):
	if skill == null or skill_name != skill.name:
		return

	level = new_level

	if level >= 3:
		_unlock_children()
	
	_update_line_color()  # Update color when level changes

func _unlock_children():
	for child in children:
		var skillchildunlocked = SkillStackManager.get_unlocked(child.skill.name)
		if not skillchildunlocked:
			child.disabled = false
			child.panel.show_behind_parent = true	
			child._highlight_line()

# Updated to use new color system
func _highlight_line():
	line_2d.default_color = UNLOCKED_COLOR
	line_2d.width = 4
	
	# If this is a parent, highlight its parent line too
	if get_parent() is SkillButtonNode:
		get_parent()._highlight_parent_line()

func _highlight_parent_line():
	line_2d.default_color = PARENT_COLOR
	line_2d.width = 5
