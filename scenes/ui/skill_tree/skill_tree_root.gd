extends Control

@onready var info_panel: SkillInfoPanel = $CanvasLayer_SkillPanel/SkillInfoPanel
@onready var skill_bar: SkillBarSkillTree = $CanvasLayer_SkillPanel/SkillBar
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

func _on_skill_selected(skill: SkillButtonNode):
	if current_skill == skill and info_panel.visible:
		# Close panel → restore full interaction
		info_panel.visible = false
		skill_bar.visible = false
		current_skill = null
		group.mouse_filter = Control.MOUSE_FILTER_STOP
		return
	
	current_skill = skill
	info_panel.show_skill(skill)
	skill_bar.visible = true
	
	# Panel open → tree clickable BUT draggable
	group.mouse_filter = Control.MOUSE_FILTER_PASS
	
	# Optional: Make info_panel ignore mouse too if you want background drag
	info_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	skill_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE

	
func _refresh_tree_from_stack():
	for btn in group.get_children():
		_refresh_recursive(btn)

func _refresh_recursive(node):
	if node is SkillButtonNode:
		node.set_skill()
	for c in node.get_children():
		_refresh_recursive(c)
