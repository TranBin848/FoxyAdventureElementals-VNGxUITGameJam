extends TextureButton
class_name SkillButtonNode

@onready var panel: Panel = $Panel
@onready var label: Label = $MarginContainer/Label
@onready var line_2d: Line2D = $Line2D
@export var skill: Skill

signal skill_selected(skill)

func _ready() -> void:
	if get_parent() is SkillButtonNode:
		line_2d.add_point(global_position + size/2)
		line_2d.add_point(get_parent().global_position + size/2)
		
	set_skill()

var level : int = 0:
	set(value):
		level = value
		label.text = str(level) + "/3"

func _on_pressed() -> void:
	level = min(level + 1, 3)
	panel.show_behind_parent = true
	
	line_2d.default_color = Color(1,1,0.247)

	for skill in get_children():
		if skill is SkillButtonNode and level == 3:
			skill.disabled = false

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
