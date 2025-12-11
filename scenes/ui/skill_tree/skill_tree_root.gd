extends Control

@onready var info_panel: SkillInfoPanel = $CanvasLayer_SkillPanel/SkillInfoPanel
@onready var group: Control = $SkillTreeButtonGroup

var current_skill: SkillButtonNode = null   # skill đang được xem

func _ready():
	#_connect_all_skill_buttons(group)
	_connect_all_skill_buttons(group)
	
	# làm mới cây từ dữ liệu stack
	_refresh_tree_from_stack()
	
	group.info_panel = info_panel
	
	
func _connect_all_skill_buttons(node):
	for child in node.get_children():
		if child is SkillButtonNode:
			child.skill_selected.connect(_on_skill_selected)
		_connect_all_skill_buttons(child)

#func connect_all_skill_buttons():
	#var group = $CanvasLayerSkillButton/SkillTreeButtonGroup
	#if group == null:
		#push_error("❌ Không tìm thấy SkillTreeButtonGroup!")
		#return
#
	#_connect_buttons_in(group)
#
#
#func _connect_buttons_in(node):
	#for child in node.get_children():
		#if child is SkillButtonNode:
			#child.skill_selected.connect(_on_skill_selected)
#
		## Duyệt tiếp nếu còn con
		#_connect_buttons_in(child)


func _on_skill_selected(skill: SkillButtonNode):
	# Nếu đang mở panel và bấm lại cùng skill → TẮT PANEL
	if current_skill == skill and info_panel.visible:
		info_panel.visible = false
		current_skill = null
		return

	# Nếu bấm skill mới → MỞ PANEL
	current_skill = skill
	info_panel.show_skill(skill)

func _refresh_tree_from_stack():
	for btn in group.get_children():
		_refresh_recursive(btn)

func _refresh_recursive(node):
	if node is SkillButtonNode:
		node.set_skill()
	for c in node.get_children():
		_refresh_recursive(c)
