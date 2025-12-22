extends TextureButton
class_name SkillButtonNode

@onready var panel: Panel = $Panel
@onready var level_label: Label = $MarginContainer/LevelLabel
@onready var stack_label: Label = $MarginContainer/StackLabel
@onready var line_2d: Line2D = $Line2D

@export var skill: Skill
@export var max_level: int = 3
@export var video_stream: VideoStream = null

var children: Array[SkillButtonNode] = []

# Line colors
const NORMAL_COLOR: Color = Color(0.5, 0.5, 0.5, 0.7)      # Gray (Path Inactive)
const UNLOCKED_COLOR: Color = Color(1, 1, 0.3, 1.0)        # Gold (Path Active)

signal skill_selected(skill)

func _ready() -> void:
	# --- Logic to draw connection to Parent ---
	if get_parent() is SkillButtonNode:
		var parent_btn: SkillButtonNode = get_parent()
		parent_btn.children.append(self)
		
		# Point 1: Center of this node
		line_2d.add_point(global_position + size / 2) 
		
		# Point 2: Center of parent node (Relative calculation)
		line_2d.add_point(parent_btn.global_position + parent_btn.size / 2)
		
		line_2d.default_color = NORMAL_COLOR
		
	# --- Connect to Managers ---
	SkillTreeManager.stack_changed.connect(_on_stack_changed)     # Runtime Stacks
	SkillTreeManager.skill_leveled_up.connect(_on_level_changed)  # Permanent Level
	SkillTreeManager.skill_unlocked.connect(_on_skill_unlocked)   # Permanent Unlock

var level : int = 0:
	set(value):
		level = value
		level_label.text = "Lvl." + str(level) + "/" + str(max_level)

var stack: int = 0
var unlocked: bool = false

func _on_pressed() -> void:
	emit_signal("skill_selected", self)

# Initialize data when opening Skill Tree
func set_skill():
	if skill == null:
		return

	if skill.texture_path:
		texture_normal = load(skill.texture_path)
	
	# 1. Load Permanent Data
	level = SkillTreeManager.get_level(skill.name)
	unlocked = SkillTreeManager.get_unlocked(skill.name)
	
	# 2. Load Runtime Data
	stack = SkillTreeManager.get_skill_stack(skill.name)
	stack_label.text = str(stack)
	
	# Update Visual State
	if unlocked:
		disabled = false
		panel.show_behind_parent = true 
	else:
		panel.show_behind_parent = false
		
	tooltip_text = skill.name
	
	# 3. Update Line Color immediately
	_update_line_color()

# --- VISUAL UPDATE LOGIC ---

func _update_line_color():
	# If I have no parent, there is no line to color
	if not (get_parent() is SkillButtonNode):
		return

	var parent_node = get_parent() as SkillButtonNode
	
	# LOGIC: The line lights up if the PATH is open.
	# The path is open if the PARENT is unlocked (even if I am still locked).
	# Naturally, if I am unlocked, my parent must have been unlocked too.
	
	if parent_node.unlocked:
		line_2d.default_color = UNLOCKED_COLOR
		line_2d.width = 4
	else:
		line_2d.default_color = NORMAL_COLOR
		line_2d.width = 2

# --- SIGNAL HANDLERS ---

func _on_skill_unlocked(skill_name_unlocked: String):
	# Case 1: THIS skill was unlocked
	if skill and skill_name_unlocked == skill.name:
		unlocked = true
		disabled = false
		panel.show_behind_parent = true
		_update_line_color()
		
		# Notify children to update their lines (because their parent - ME - just unlocked)
		for child in children:
			child._update_line_color()
			
	# Case 2: My PARENT was unlocked
	# I need to check if the unlocked skill belongs to my parent
	if get_parent() is SkillButtonNode:
		var parent_skill = get_parent().skill
		if parent_skill and skill_name_unlocked == parent_skill.name:
			# My parent just unlocked, so the path to me is now valid -> Light up my line
			_update_line_color()

func _on_stack_changed(skill_name: String, new_stack: int):
	if skill == null or skill_name != skill.name:
		return
	stack = new_stack
	stack_label.text = str(stack)

func _on_level_changed(skill_name: String, new_level: int):
	if skill == null or skill_name != skill.name:
		return
	level = new_level
	# Level up doesn't usually change line color, but if it affects unlock status logic:
	_update_line_color()
