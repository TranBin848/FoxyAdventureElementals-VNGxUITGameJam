# ============================================================================
# SKILL_TREE_UI.GD - Fixed for Instantiated Scene (No @export needed)
# ============================================================================
extends CanvasLayer
class_name SkillTreeUI

signal skill_tree_toggled(state)

# Use @onready with paths instead of @export since everything is in same scene
@onready var tree_controller: Control = $SkillTreeRoot
@onready var info_panel_ultimate: SkillInfoPanelUltimate = $SkillInfoPanelUltimate
@onready var info_panel: SkillInfoPanel = $SkillInfoPanel
@onready var skill_bar_preview: SkillBarSkillTree = $SkillBar
@onready var notification_label: Label = $NotiLabel

var _tree_camera: Camera2D

func _ready():
	print("🔍 SkillTreeUI initializing...")
	print("  tree_controller: %s" % tree_controller)
	print("  info_panel: %s" % info_panel)
	print("  info_panel_ultimate: %s" % info_panel_ultimate)
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
	
	# Connect info panel errors (both panels)
	if info_panel:
		if info_panel.has_signal("error_occurred"):
			info_panel.error_occurred.connect(_on_error_occurred)
			print("  ✅ Connected info_panel error signal")
	if info_panel_ultimate:
		if info_panel_ultimate.has_signal("error_occurred"):
			info_panel_ultimate.error_occurred.connect(_on_error_occurred)
			print("  ✅ Connected info_panel_ultimate error signal")
	
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
	skill_tree_toggled.emit(visible)
	# HOOK HERE
	GameProgressManager.trigger_event("SKILL_TREE")
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

func _on_show_panel_requested(skill_node: SkillButtonNode):  # Accept Node for both regular and ultimate
	"""Show appropriate info panel when skill button clicked"""
	if not skill_node:
		push_error("Invalid skill node received!")
		return
	
	var skill = skill_node.skill
	if not skill:
		push_error("SkillButtonNode has no skill resource!")
		return
	
	print("📊 Opening panel for: %s (type: %s)" % [skill.name, skill.get("type")])
	
	# FIXED: Complete ultimate vs regular skill logic
	if skill.get("type") == "ultimate":
		if info_panel_ultimate:
			info_panel_ultimate.show_skill(skill_node)
			info_panel.visible = false
			info_panel_ultimate.visible = true
			print("  🎭 Showed Ultimate panel")
		else:
			push_error("info_panel_ultimate is null!")
	else:
		if info_panel:
			info_panel.show_skill(skill_node)
			info_panel.visible = true
			info_panel_ultimate.visible = false
			print("  📋 Showed Regular panel")
		else:
			push_error("info_panel is null!")
	
	# Show skill bar preview
	if skill_bar_preview:
		skill_bar_preview.visible = true

func _on_hide_panel_requested():
	"""Hide all info panels"""
	if info_panel:
		info_panel.visible = false
	if info_panel_ultimate:
		info_panel_ultimate.visible = false
	# Keep skill bar visible for overview (uncomment to hide):
	# if skill_bar_preview:
	# 	skill_bar_preview.visible = false
	
	print("❌ All panels closed")

func _on_error_occurred(msg: String):
	"""Display notification messages"""
	if not notification_label:
		print("📢 %s" % msg)
		return
	
	# Ensure it renders on top
	notification_label.z_index = 10 
	
	notification_label.text = msg
	notification_label.visible = true
	notification_label.modulate.a = 1.0
	
	var tween = create_tween()
	
	# CRITICAL FIX: Allow tween to run while game is paused
	tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS) 
	
	tween.tween_interval(2.0)
	tween.tween_property(notification_label, "modulate:a", 0.0, 0.3)
	tween.tween_callback(func(): notification_label.visible = false)
