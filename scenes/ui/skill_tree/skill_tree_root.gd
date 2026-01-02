# ============================================================================
# SKILL_TREE_ROOT.GD - Fixed for Instantiated Scene (No @export needed)
# ============================================================================
extends Control

signal request_show_panel(skill_node: SkillButtonNode)
signal request_hide_panel()

# Use @onready with paths - nodes are INSIDE this scene
@onready var camera: Camera2D = $SubViewportContainer/SubViewport/SkillCamera2D
@onready var button_group: Control = $SubViewportContainer/SubViewport/SkillTreeButtonGroup

# Camera settings
var zoom_min := Vector2(0.5, 0.5)
var zoom_max := Vector2(2.5, 2.5)
var zoom_speed := 0.2
var dragging := false
var last_mouse_pos := Vector2.ZERO
var current_skill_button: SkillButtonNode = null

func _ready():
	print("🔍 SkillTreeRoot initializing...")
	print("  camera: %s" % camera)
	print("  button_group: %s" % button_group)
	
	if not button_group:
		push_error("SkillTreeRoot: button_group not found!")
		return
	
	if not camera:
		push_error("SkillTreeRoot: camera not found!")
		return
	
	call_deferred("_initialize")

func _initialize():
	_connect_buttons_recursive(button_group)
	refresh_visuals()
	print("✅ SkillTreeRoot initialized\n")

func get_skill_camera() -> Camera2D:
	return camera

func _connect_buttons_recursive(node: Node):
	if not node:
		return
	
	for child in node.get_children():
		if child is SkillButtonNode:
			if not child.skill_node_selected.is_connected(_on_button_clicked):
				child.skill_node_selected.connect(_on_button_clicked)
				print("  🔗 Connected: %s" % (child.skill.name if child.skill else child.name))
		_connect_buttons_recursive(child)

func refresh_visuals():
	"""Tell all buttons to refresh from SkillTreeManager"""
	if not button_group:
		return
	
	print("🔄 Refreshing button visuals...")
	_refresh_recursive(button_group)
	print("✅ Refresh complete")

func _refresh_recursive(node: Node):
	if node is SkillButtonNode:
		node.refresh_visual()
	for child in node.get_children():
		_refresh_recursive(child)

func _on_button_clicked(btn: SkillButtonNode):
	"""Handle button click - toggle panel if same button clicked"""
	print("🖱️ Button clicked: %s" % (btn.skill.name if btn.skill else "unnamed"))
	
	# Toggle: If clicking the same button, close panel
	if current_skill_button == btn:
		print("  ↩️ Same button - closing panel")
		current_skill_button = null
		request_hide_panel.emit()
		return
	
	# Open panel for new button
	current_skill_button = btn
	request_show_panel.emit(btn)

# ============================================================================
# CAMERA CONTROLS
# ============================================================================

func _gui_input(event):
	if not visible:
		return
	
	# Don't process if input was already handled
	if event.is_action("ui_skilltree"):
		return
	
	# Zoom
	if event is InputEventMouseButton and event.is_pressed():
		if event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			_apply_zoom(-zoom_speed)
		elif event.button_index == MOUSE_BUTTON_WHEEL_UP:
			_apply_zoom(zoom_speed)
	
	# Drag
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		dragging = event.is_pressed()
		last_mouse_pos = get_viewport().get_mouse_position()
		
		# Close panel when clicking empty space
		if dragging and not _is_mouse_over_button():
			if current_skill_button:
				current_skill_button = null
				request_hide_panel.emit()
	
	if event is InputEventMouseMotion and dragging:
		var mouse_pos = get_viewport().get_mouse_position()
		var delta = mouse_pos - last_mouse_pos
		if camera:
			camera.global_position -= delta / camera.zoom
		last_mouse_pos = mouse_pos

func _apply_zoom(delta: float):
	if not camera:
		return
	var new_zoom = camera.zoom + Vector2(delta, delta)
	new_zoom.x = clamp(new_zoom.x, zoom_min.x, zoom_max.x)
	new_zoom.y = clamp(new_zoom.y, zoom_min.y, zoom_max.y)
	camera.zoom = new_zoom

func _is_mouse_over_button() -> bool:
	# Buttons will handle their own clicks
	return false
