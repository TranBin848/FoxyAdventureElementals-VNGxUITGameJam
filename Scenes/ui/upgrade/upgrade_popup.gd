class_name StatUpgradePopup
extends MarginContainer

@export var stat_row_scene: PackedScene
@export var available_stats: Array[PlayerStat] # Typed Array

@onready var stats_container: VBoxContainer = $NinePatchRect/MarginContainer/VBoxContainer/StatsContainer
@onready var points_label: Label = $NinePatchRect/MarginContainer/VBoxContainer/HeaderLabel
@onready var close_button: TextureButton = $NinePatchRect/CloseTextureButton
@onready var overlay: ColorRect = $OverlayColorRect

# --- NEW BUTTONS ---
# Make sure to update these paths to match your scene tree!
@onready var apply_button: Button = $NinePatchRect/MarginContainer/VBoxContainer/ButtonsContainer/ApplyButton
@onready var reset_button: Button = $NinePatchRect/MarginContainer/VBoxContainer/ButtonsContainer/ResetButton

# Tracks points added in this staging session (Not yet committed)
var session_added_points: Dictionary = {}

func _ready() -> void:
	get_tree().paused = true
	
	if not stats_container or not stat_row_scene:
		push_error("StatUpgradePopup: Missing container or row scene.")
		queue_free()
		return

	# Initialize tracking
	for stat in available_stats:
		session_added_points[stat.type] = 0
	
	if close_button: close_button.pressed.connect(hide_popup)
	if overlay: overlay.gui_input.connect(_on_overlay_gui_input)
	
	# Connect new buttons
	if apply_button: apply_button.pressed.connect(_on_apply_pressed)
	if reset_button: reset_button.pressed.connect(_on_reset_pressed)
	
	_refresh_ui()

func _exit_tree() -> void:
	get_tree().paused = false

func _refresh_ui() -> void:
	# 1. Calculate Virtual State (Current + Staged Changes)
	var real_coins = GameManager.inventory_system.coins
	var staged_cost = _calculate_staged_cost()
	var virtual_coins = real_coins - staged_cost
	
	# 2. Update Header
	if points_label:
		points_label.text = "%d Points Remaining" % virtual_coins
		# Optional: Turn text red if negative (shouldn't happen with checks, but good for debug)
		points_label.modulate = Color.RED if virtual_coins < 0 else Color.WHITE
	
	# 3. Manage Buttons State
	# Only enable Apply/Reset if we have actually made changes
	var has_changes = staged_cost > 0
	if apply_button: apply_button.disabled = not has_changes
	if reset_button: reset_button.disabled = not has_changes

	# 4. Clear old rows
	for child in stats_container.get_children():
		child.queue_free()
	
	# 5. Create new rows
	for stat in available_stats:
		var row = stat_row_scene.instantiate()
		stats_container.add_child(row)
		
		# We show: Real Base Value + Staged Value
		var base_val = GameManager.get_player_stat(stat.type)
		var staged_val = session_added_points[stat.type]
		var preview_val = base_val + staged_val
		
		row.setup(stat, preview_val)
		row.stat_changed.connect(_on_stat_change_requested)
		
		# Logic: 
		# Can Decrease: Only if we have added points in this session
		# Can Increase: Only if we have enough VIRTUAL coins left
		var can_decrease = staged_val > 0
		row.update_buttons(virtual_coins, can_decrease)

func _on_stat_change_requested(stat_def: PlayerStat, change: int) -> void:
	# IMPORTANT: We do NOT call GameManager here. We only update local dictionary.
	
	var real_coins = GameManager.inventory_system.coins
	var current_staged_cost = _calculate_staged_cost()
	var virtual_coins_available = real_coins - current_staged_cost
	
	if change > 0:
		# Check if we can afford it with virtual coins
		if virtual_coins_available >= stat_def.cost_per_point:
			session_added_points[stat_def.type] += 1
			_refresh_ui()
			
	elif change < 0:
		# Check if we have staged points to refund
		if session_added_points[stat_def.type] > 0:
			session_added_points[stat_def.type] -= 1
			_refresh_ui()

func _on_apply_pressed() -> void:
	# Loop through all stats in our "Staging" dictionary
	for stat in available_stats:
		var points_to_add = session_added_points[stat.type]
		
		# If we added points to this stat...
		if points_to_add > 0:
			# Call GameManager for EACH point. 
			# This ensures GameManager deducts the cost and validates coins for every single point.
			for i in range(points_to_add):
				GameManager.modify_stat(stat, 1)
			
			# Reset the staging tracker for this stat
			session_added_points[stat.type] = 0

	# NOTE: We removed the manual 'inventory_system.coins -= total_cost' line
	# because GameManager.modify_stat() already does it!
	
	# Refresh UI to show the new "Base" state
	_refresh_ui()
	
func _on_reset_pressed() -> void:
	# Simply wipe the local tracker
	for key in session_added_points:
		session_added_points[key] = 0
	_refresh_ui()

func _calculate_staged_cost() -> int:
	var total = 0
	for stat in available_stats:
		var count = session_added_points.get(stat.type, 0)
		total += count * stat.cost_per_point
	return total

func hide_popup() -> void:
	# Optional: Auto-reset or Auto-apply on close? 
	# For now, let's just close (discarding changes).
	queue_free()

func _on_overlay_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		hide_popup()
