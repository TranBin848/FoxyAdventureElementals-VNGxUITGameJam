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
	# Validate skill assignment
	if not skill:
		push_error("⚠️ SkillButtonNode '%s' has no skill assigned!" % name)
		return
	
	# Connect pressed signal
	if not pressed.is_connected(_on_pressed):
		pressed.connect(_on_pressed)
	
	# Setup parent-child relationships
	if get_parent() is SkillButtonNode:
		var parent_btn: SkillButtonNode = get_parent()
		parent_btn.children.append(self)
		
		if line_2d:
			line_2d.add_point(global_position + size / 2)
			line_2d.add_point(parent_btn.global_position + parent_btn.size / 2)
			line_2d.default_color = NORMAL_COLOR
	
	# Connect to SkillTreeManager signals
	if SkillTreeManager:
		if not SkillTreeManager.stack_changed.is_connected(_on_stack_changed):
			SkillTreeManager.stack_changed.connect(_on_stack_changed)
		if not SkillTreeManager.skill_leveled_up.is_connected(_on_level_changed):
			SkillTreeManager.skill_leveled_up.connect(_on_level_changed)
		if not SkillTreeManager.skill_unlocked.is_connected(_on_skill_unlocked):
			SkillTreeManager.skill_unlocked.connect(_on_skill_unlocked)
		
		# Initial refresh after connections are established
		call_deferred("refresh_visual")
	else:
		push_error("❌ SkillTreeManager not found!")

func _on_pressed() -> void:
	if skill:
		skill_node_selected.emit(self)
	else:
		push_error("Button '%s' pressed but has no skill!" % name)

func refresh_visual() -> void:
	"""Update visuals from SkillTreeManager state"""
	
	if not skill:
		push_error("Cannot refresh visual - no skill assigned to '%s'" % name)
		return
	
	# Load texture
	if skill.texture_path and skill.texture_path.strip_edges() != "":
		var texture = load(skill.texture_path)
		if texture:
			texture_normal = texture
		else:
			push_error("Failed to load texture: %s" % skill.texture_path)
	
	# Check if ultimate skill
	var is_ultimate = skill.get("type") == "ultimate"
	
	if is_ultimate:
		# Hide labels for ultimate skills
		if level_label:
			level_label.visible = false
		if stack_label:
			stack_label.visible = false
		if panel:
			panel.visible = false
	else:
		# Show and update labels for normal skills
		var is_unlocked = SkillTreeManager.is_unlocked(skill.name)
		var level = SkillTreeManager.get_level(skill.name)
		var stacks = SkillTreeManager.get_stacks(skill.name)
		
		if level_label:
			level_label.visible = true
			level_label.text = "Lv.%d/%d" % [level, max_level]
		
		if stack_label:
			stack_label.visible = true
			stack_label.text = str(stacks)
		
		if panel:
			panel.visible = true
			panel.show_behind_parent = is_unlocked
	
	tooltip_text = skill.name if skill else "No Skill"
	_update_line_color()

func _update_line_color() -> void:
	if not line_2d:
		return
		
	if not (get_parent() is SkillButtonNode):
		return
	
	var parent_node = get_parent() as SkillButtonNode
	if not parent_node.skill:
		return
	
	# Hide line if parent is ultimate
	if parent_node.skill.get("type") == "ultimate":
		line_2d.visible = false
		return
	
	line_2d.visible = true
	
	if SkillTreeManager.is_unlocked(parent_node.skill.name):
		line_2d.default_color = UNLOCKED_COLOR
		line_2d.width = 4
	else:
		line_2d.default_color = NORMAL_COLOR
		line_2d.width = 2

# ============================================================================
# SIGNAL HANDLERS
# ============================================================================

func _on_skill_unlocked(skill_name: String) -> void:
	if skill and skill_name == skill.name:
		refresh_visual()
		# Update children's lines
		for child in children:
			if child and is_instance_valid(child):
				child._update_line_color()
	
	# Update line to parent if parent was unlocked
	if get_parent() is SkillButtonNode:
		var parent_skill = (get_parent() as SkillButtonNode).skill
		if parent_skill and skill_name == parent_skill.name:
			_update_line_color()

func _on_stack_changed(skill_name: String, new_stack: int) -> void:
	if skill and skill_name == skill.name:
		if stack_label:
			stack_label.text = str(new_stack)

func _on_level_changed(skill_name: String, new_level: int) -> void:
	if skill and skill_name == skill.name:
		if level_label:
			level_label.text = "Lv.%d/%d" % [new_level, max_level]