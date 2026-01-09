# ============================================================================
# BUTTON DIAGNOSTIC - Attach to ONE button (e.g., FireShot) temporarily
# ============================================================================
extends TextureButton
class_name SkillButtonNode

@onready var panel: Panel = $Panel
@onready var level_label: Label = $MarginContainer/LevelLabel
@onready var stack_label: Label = $MarginContainer/StackLabel
@onready var line_2d: Line2D = $Line2D

@export var skill: Skill
@export var max_level: int = 10
@export var video_stream: VideoStream = null

var children: Array[SkillButtonNode] = []

const NORMAL_COLOR: Color = Color(0.5, 0.5, 0.5, 0.7)
const UNLOCKED_COLOR: Color = Color(1, 1, 0.3, 1.0)

signal skill_node_selected(button_node: SkillButtonNode)

func _ready() -> void:
	
	# Check if pressed signal exists
	var has_pressed = has_signal("pressed")
	
	# Connect pressed signal
	if has_pressed:
		pressed.connect(_on_pressed)
	else:
		push_error("  ❌ CRITICAL: Button has no 'pressed' signal!")
	
	# Setup parent-child relationships
	if get_parent() is SkillButtonNode:
		var parent_btn: SkillButtonNode = get_parent()
		parent_btn.children.append(self)
		
		line_2d.add_point(global_position + size / 2)
		line_2d.add_point(parent_btn.global_position + parent_btn.size / 2)
		line_2d.default_color = NORMAL_COLOR
	
	# Connect to SkillTreeManager signals
	if SkillTreeManager:
		if SkillTreeManager.has_signal("stack_changed"):
			SkillTreeManager.stack_changed.connect(_on_stack_changed)
		if SkillTreeManager.has_signal("skill_leveled_up"):
			SkillTreeManager.skill_leveled_up.connect(_on_level_changed)
		if SkillTreeManager.has_signal("skill_unlocked"):
			SkillTreeManager.skill_unlocked.connect(_on_skill_unlocked)
	else:
		push_error("  ❌ CRITICAL: SkillTreeManager not found!")
	

func _on_pressed() -> void:
	skill_node_selected.emit(self)

func refresh_visual() -> void:
	"""Update visuals from SkillTreeManager state"""
	
	if not skill:
		return
	
	if skill.texture_path:
		texture_normal = load(skill.texture_path)
	
	var is_unlocked = SkillTreeManager.is_unlocked(skill.name)
	var level = SkillTreeManager.get_level(skill.name)
	var stacks = SkillTreeManager.get_stacks(skill.name)
	
	# --- NEW LOGIC START ---
	if skill.get("type") == "ultimate":
		# Hide labels for ultimate skills
		level_label.visible = false
		stack_label.visible = false
		panel.visible = false
	else:
		# Show and update labels for normal skills
		level_label.visible = true
		stack_label.visible = true
		level_label.text = "Lv.%d/%d" % [level, max_level]
		stack_label.text = str(stacks)
	# --- NEW LOGIC END ---
	
	panel.show_behind_parent = is_unlocked
	tooltip_text = skill.name
	
	_update_line_color()
func _update_line_color() -> void:
	if not (get_parent() is SkillButtonNode):
		return
	
	var parent_node = get_parent() as SkillButtonNode
	if parent_node.skill and parent_node.skill.get("type") == "ultimate":
		line_2d.visible = false
		return
	if SkillTreeManager.is_unlocked(parent_node.skill.name):
		line_2d.default_color = UNLOCKED_COLOR
		line_2d.width = 4
	else:
		line_2d.default_color = NORMAL_COLOR
		line_2d.width = 2

# Signal handlers
func _on_skill_unlocked(skill_name: String) -> void:
	if skill and skill_name == skill.name:
		refresh_visual()
		for child in children:
			child._update_line_color()
	
	if get_parent() is SkillButtonNode:
		var parent_skill = get_parent().skill
		if parent_skill and skill_name == parent_skill.name:
			_update_line_color()

func _on_stack_changed(skill_name: String, new_stack: int) -> void:
	if skill and skill_name == skill.name:
		stack_label.text = str(new_stack)

func _on_level_changed(skill_name: String, new_level: int) -> void:
	if skill and skill_name == skill.name:
		level_label.text = "Lv.%d/%d" % [new_level, max_level]
