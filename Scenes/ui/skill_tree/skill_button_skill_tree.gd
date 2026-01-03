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
@export var max_level: int = 3
@export var video_stream: VideoStream = null

var children: Array[SkillButtonNode] = []

const NORMAL_COLOR: Color = Color(0.5, 0.5, 0.5, 0.7)
const UNLOCKED_COLOR: Color = Color(1, 1, 0.3, 1.0)

signal skill_node_selected(button_node: SkillButtonNode)

func _ready() -> void:
	print("🔍 BUTTON DIAGNOSTIC: %s" % name)
	
	# Check basic properties
	print("📋 BUTTON PROPERTIES:")
	print("  disabled: %s" % disabled)
	print("  mouse_filter: %s" % mouse_filter)
	print("  visible: %s" % visible)
	print("  skill assigned: %s" % (skill != null))
	if skill:
		print("  skill.name: %s" % skill.name)
	
	# Check if pressed signal exists
	print("\n🔌 SIGNAL CHECK:")
	var has_pressed = has_signal("pressed")
	print("  'pressed' signal exists: %s" % ("✅" if has_pressed else "❌"))
	
	# Connect pressed signal
	if has_pressed:
		pressed.connect(_on_pressed)
		print("  ✅ Connected pressed signal to _on_pressed()")
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
	print("\n🌐 MANAGER SIGNALS:")
	if SkillTreeManager:
		print("  SkillTreeManager exists: ✅")
		if SkillTreeManager.has_signal("stack_changed"):
			SkillTreeManager.stack_changed.connect(_on_stack_changed)
			print("  ✅ Connected to stack_changed")
		else:
			print("  ❌ stack_changed signal not found")
		
		if SkillTreeManager.has_signal("skill_leveled_up"):
			SkillTreeManager.skill_leveled_up.connect(_on_level_changed)
			print("  ✅ Connected to skill_leveled_up")
		
		if SkillTreeManager.has_signal("skill_unlocked"):
			SkillTreeManager.skill_unlocked.connect(_on_skill_unlocked)
			print("  ✅ Connected to skill_unlocked")
	else:
		push_error("  ❌ CRITICAL: SkillTreeManager not found!")
	

func _on_pressed() -> void:
	print("🖱️ _on_pressed() CALLED for %s" % name)
	print("  Emitting skill_node_selected signal...")
	skill_node_selected.emit(self)
	print("  ✅ Signal emitted")

func _gui_input(event):
	# Debug input events
	if event is InputEventMouseButton:
		print("🖱️ Mouse event on %s: button=%d, pressed=%s" % [name, event.button_index, event.pressed])

func refresh_visual() -> void:
	"""Update visuals from SkillTreeManager state"""
	print("🔄 refresh_visual() called for %s" % name)
	
	if not skill:
		print("  ⚠️ No skill assigned")
		return
	
	if skill.texture_path:
		texture_normal = load(skill.texture_path)
	
	var is_unlocked = SkillTreeManager.is_unlocked(skill.name)
	var level = SkillTreeManager.get_level(skill.name)
	var stacks = SkillTreeManager.get_stacks(skill.name)
	
	print("  %s: unlocked=%s, level=%d, stacks=%d" % [skill.name, is_unlocked, level, stacks])
	
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
	
	print("  disabled set to: %s" % disabled)
	
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
		print("✨ %s unlocked!" % skill_name)
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
