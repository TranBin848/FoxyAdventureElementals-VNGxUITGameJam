extends TextureButton
class_name SkillButtonNode

@onready var panel: Panel = $Panel
@onready var label: Label = $MarginContainer/Label
@onready var line_2d: Line2D = $Line2D
@export var skill: Skill

var unlocked: bool = false
@export var require_stack_unlock := 1
@export var require_stack_upgrade := 1

var children: Array[SkillButtonNode] = []

signal skill_selected(skill)

func _ready() -> void:
	
	if get_parent() is SkillButtonNode:
		var parent_btn: SkillButtonNode = get_parent()
		parent_btn.children.append(self)
		
		line_2d.add_point(global_position + size/2)
		line_2d.add_point(get_parent().global_position + size/2)
		
	set_skill()
	SkillStackManager.stack_changed.connect(_on_stack_changed)
var level : int = 0:
	set(value):
		level = value
		label.text = str(level) + "/3"

func _on_pressed() -> void:
	#level = min(level + 1, 3)
	#panel.show_behind_parent = true
	#
	#line_2d.default_color = Color(1,1,0.247)
#
	#for skill in get_children():
		#if skill is SkillButtonNode and level == 3:
			#skill.disabled = false

	# Phát tín hiệu để UI bên phải xử lý
	emit_signal("skill_selected", self)

func set_skill():
	if skill == null:
		return

	# Cập nhật texture
	if skill.texture:
		texture_normal = skill.texture
	
	# Cập nhật level từ skill (nếu muốn)
	level = skill.current_stack

	# Đặt tooltip hoặc tên nếu cần
	tooltip_text = skill.name
	
	#if not unlocked:
		#disabled = true
		#modulate = Color(0.5,0.5,0.5)
	
func lock_button():
	modulate = Color(0.5, 0.5, 0.5) # tối màu

func unlock_button():
	disabled = false
	modulate = Color(1,1,1) # sáng lại

func _on_stack_changed(skill_name: String, new_value: int):
	if skill == null:
		return

	# Nếu skill của node này trùng với skill player nhặt
	if skill.name != skill_name:
		return

	# Cập nhật level hiển thị
	level = new_value  

	# Kiểm tra unlock
	if not unlocked and new_value >= require_stack_unlock:
		unlocked = true
		disabled = false
		modulate = Color(1,1,1)

	# Kiểm tra upgrade
	if unlocked and level >= require_stack_upgrade and level < 3:
		# Có thể nâng cấp → bật nút upgrade trong SkillInfoPanel
		pass

	# Nếu max level → mở khóa children
	if level == 3:
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
