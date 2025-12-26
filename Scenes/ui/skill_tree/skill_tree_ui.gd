# ============================================================================
# SKILL_TREE_UI.GD - Fixed for Instantiated Scene (No @export needed)
# ============================================================================
extends CanvasLayer
class_name SkillTreeUI

# Use @onready with paths instead of @export since everything is in same scene
@onready var tree_controller: Control = $SkillTreeRoot
@onready var info_panel: SkillInfoPanel = $SkillInfoPanel
@onready var skill_bar_preview: SkillBarSkillTree = $SkillBar
@onready var notification_label: Label = $NotiLabel

var _tree_camera: Camera2D

func _ready():
	print("🔍 SkillTreeUI initializing...")
	print("  tree_controller: %s" % tree_controller)
	print("  info_panel: %s" % info_panel)
	print("  skill_bar_preview: %s" % skill_bar_preview)
	print("  notification_label: %s" % notification_label)
	
	# Get camera from tree_controller
	if tree_controller:
		_tree_camera = tree_controller.get_node_or_null("SubViewportContainer/SubViewport/SkillCamera2D")
		if _tree_camera:
			print("  ✅ Found camera: %s" % _tree_camera)
		else:
			push_error("  ❌ Camera not found at expected path")
	
	# Connect controller signals
	if tree_controller:
		if tree_controller.has_signal("request_show_panel"):
			tree_controller.request_show_panel.connect(_on_show_panel_requested)
			print("  ✅ Connected request_show_panel signal")
		if tree_controller.has_signal("request_hide_panel"):
			tree_controller.request_hide_panel.connect(_on_hide_panel_requested)
			print("  ✅ Connected request_hide_panel signal")
	
	# Connect info panel errors
	if info_panel:
		if info_panel.has_signal("error_occurred"):
			info_panel.error_occurred.connect(_on_error_occurred)
			print("  ✅ Connected error_occurred signal")
	
	visible = false
	print("✅ SkillTreeUI initialization complete\n")

func _input(event):
	if event.is_action_pressed("ui_skilltree"):
		print("⌨️ Tab key pressed!")
		toggle_ui()
		get_viewport().set_input_as_handled()

func toggle_ui():
	visible = !visible
	get_tree().paused = visible
	
	print("🔄 Toggle UI: visible=%s, paused=%s" % [visible, get_tree().paused])
	
	if visible:
		_open_logic()
	else:
		_close_logic()

func _open_logic():
	print("🌳 Opening Skill Tree")
	
	# Switch to skill tree camera
	if GameManager and GameManager.player:
		GameManager.player.camera_2d.enabled = false
		print("  📷 Disabled player camera")
	
	if _tree_camera:
		_tree_camera.enabled = true
		_tree_camera.make_current()
		print("  📷 Enabled skill tree camera")
	
	# Refresh visuals from SkillTreeManager
	if tree_controller and tree_controller.has_method("refresh_visuals"):
		tree_controller.refresh_visuals()
		print("  🔄 Refreshed tree visuals")
	
	if skill_bar_preview and skill_bar_preview.has_method("_sync_from_manager"):
		skill_bar_preview._sync_from_manager()
		print("  🔄 Synced skill bar")

func _close_logic():
	print("🌳 Closing Skill Tree")
	
	# Restore player camera
	if _tree_camera:
		_tree_camera.enabled = false
		print("  📷 Disabled skill tree camera")
	
	if GameManager and GameManager.player:
		GameManager.player.camera_2d.enabled = true
		GameManager.player.camera_2d.make_current()
		print("  📷 Re-enabled player camera")
	
	# Hide all panels
	_on_hide_panel_requested()

func _on_show_panel_requested(skill_node: SkillButtonNode):
	"""Show info panel when skill button clicked"""
	if not info_panel:
		push_error("info_panel is null!")
		return
	
	if not skill_node.skill:
		push_error("SkillButtonNode has no skill resource!")
		return
	
	print("📊 Opening panel for: %s" % skill_node.skill.name)
	
	info_panel.show_skill(skill_node)
	info_panel.visible = true
	
	if skill_bar_preview:
		skill_bar_preview.visible = true

func _on_hide_panel_requested():
	"""Hide info panel"""
	if info_panel:
		info_panel.visible = false
	#if skill_bar_preview:
		#skill_bar_preview.visible = false
	
	print("❌ Panel closed")

func _on_error_occurred(msg: String):
	"""Display notification messages"""
	if not notification_label:
		print("📢 %s" % msg)
		return
	
	# 1. Ensure it renders on top (optional code fix, better to do in Editor)
	notification_label.z_index = 10 
	
	notification_label.text = msg
	notification_label.visible = true
	notification_label.modulate.a = 1.0
	
	var tween = create_tween()
	
	# 2. CRITICAL FIX: Allow tween to run while game is paused
	tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS) 
	
	tween.tween_interval(2.0)
	tween.tween_property(notification_label, "modulate:a", 0.0, 0.3)
	tween.tween_callback(func(): notification_label.visible = false)
