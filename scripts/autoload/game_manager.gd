extends Node

#region Configuration & Resources
@export_group("UI & Scenes")
@export var upgrade_popup_scene: PackedScene = preload("res://scenes/ui/upgrade/upgrade_popup.tscn")
@export_group("Stats Data")
@export var stat_definitions: Array[Resource] = [] # Drag ALL your PlayerStat .tres files here!
#endregion

#region State Variables
# --- Portal & Stage ---
var target_portal_name: String = ""
var current_stage: Node = null
var current_level: int = 0
var player: Player = null
var skill_bar: SkillBar = null
var minimap: Minimap = null

# --- Checkpoint & Save ---
var current_checkpoint_id: String = ""
var checkpoint_data: Dictionary = {}
signal checkpoint_changed(new_checkpoint_id: String)
signal checkpoint_loading_complete()

# --- Inventory & Systems ---
var inventory_system: InventorySystem = null

# --- Stat Storage ---
# Stores { "max_health": 5, "attack": 2 } (Points Allocated, NOT final values)
var player_stats: Dictionary = {} 
#endregion

func _ready() -> void:
	# Initialize Systems
	inventory_system = InventorySystem.new()
	add_child(inventory_system)
	
	# Load Data
	#load_checkpoint_data()
	
	# Connect Scene Handling
	get_tree().tree_changed.connect(_on_tree_changed)
	
	# Trigger once for the initial load
	call_deferred("_on_scene_changed")

#region Scene Management
func _on_tree_changed() -> void:
	# If the engine has swapped the current scene, and it's different from our cache:
	if !get_tree(): return
	if get_tree().current_scene and get_tree().current_scene != current_stage:
		_on_scene_changed()

func _on_scene_changed() -> void:
	current_stage = get_tree().current_scene
	if current_stage == null: return

	# Refresh References
	player = current_stage.find_child("Player", true, false)
	var skillbarroot = current_stage.find_child("SkillBarUI", true, false)
	if skillbarroot:
		skill_bar = skillbarroot.get_node("MarginContainer/SkillBar")

	# Scale Enemies
	get_tree().call_group("enemies", "scale_health", 0.8 + 0.2 * current_level)

	# Validate & Respawn
	_handle_checkpoint_validation()

func change_stage(stage_path: String, _target_portal_name: String = "") -> void:
	target_portal_name = _target_portal_name
	get_tree().change_scene_to_file(stage_path)

func respawn_at_portal() -> bool:
	if target_portal_name.is_empty() or not current_stage or not player:
		return false
		
	var door = current_stage.find_child(target_portal_name)
	if door:
		player.global_position = door.global_position
		target_portal_name = ""
		return true
	return false

func _handle_checkpoint_validation() -> void:
	if current_checkpoint_id.is_empty(): return

	var saved_stage_path := ""
	
	# Get path from memory OR disk
	if checkpoint_data.has(current_checkpoint_id):
		saved_stage_path = checkpoint_data[current_checkpoint_id].get("stage_path", "")
	else:
		var save_file_data = SaveSystem.load_checkpoint_data()
		saved_stage_path = save_file_data.get("stage_path", "")

	# If scene doesn't match checkpoint, the checkpoint is invalid/old
	if current_stage.scene_file_path != saved_stage_path:
		clear_checkpoint_data()
	elif player:
		# If scene matches, respawn player at checkpoint pos
		await get_tree().create_timer(0.1).timeout
		respawn_at_checkpoint()
#endregion

#region Save & Load System
func save_checkpoint(checkpoint_id: String) -> void:
	if not player: return

	current_checkpoint_id = checkpoint_id
	checkpoint_changed.emit(checkpoint_id)

	# Gather Data
	var player_state_dict = player.save_state()
	var inventory_data = inventory_system.save_data() if inventory_system else {}
	
	# Update Memory
	checkpoint_data.clear()
	checkpoint_data[checkpoint_id] = {
		"player_state": player_state_dict,
		"inventory_data": inventory_data,
		"player_stats": player_stats.duplicate(), # Save allocated stat points
		"stage_path": current_stage.scene_file_path
	}

	# Write to Disk
	SaveSystem.save_checkpoint_data(
		checkpoint_id,
		checkpoint_data[checkpoint_id],
		current_stage.scene_file_path,
		SkillTreeManager.save_data()
	)

func load_checkpoint_data() -> void:
	var save_data = SaveSystem.load_checkpoint_data()
	if save_data.is_empty(): return

	current_checkpoint_id = save_data.get("checkpoint_id", "")
	var loaded_player_data = save_data.get("player", {}) # This is the checkpoint_data wrapper
	
	# Load Sub-systems
	if inventory_system:
		inventory_system.load_data(loaded_player_data.get("inventory_data", {}))
	
	SkillTreeManager.load_data(save_data.get("skill_tree", {}))
	
	# Load Stats
	player_stats = loaded_player_data.get("player_stats", {}).duplicate()

	# Store in memory
	if not current_checkpoint_id.is_empty():
		checkpoint_data.clear()
		checkpoint_data[current_checkpoint_id] = loaded_player_data

func respawn_at_checkpoint() -> void:
	if current_checkpoint_id.is_empty(): return

	var data = checkpoint_data.get(current_checkpoint_id, {})
	if data.is_empty() or not player: return

	# 1. Load Position/Flags
	player.load_state(data.get("player_state", {}))
	
	# 2. Re-apply Stats (calculate total health/speed based on saved points)
	_reapply_all_stats()

	# 3. Restore Inventory
	if inventory_system:
		inventory_system.load_data(data.get("inventory_data", {}))
		
	checkpoint_loading_complete.emit()

func clear_checkpoint_data() -> void:
	current_checkpoint_id = ""
	checkpoint_data.clear()
	player_stats.clear()
	SaveSystem.delete_save_file()
#endregion

#region Stat & Upgrade System
func _show_upgrade_popup() -> void:
	var gui = current_stage.find_child("GUI", true, false)
	if gui:
		var popup = upgrade_popup_scene.instantiate()
		gui.add_child(popup)

func get_player_stat(stat_type: String) -> int:
	return player_stats.get(stat_type, 0)

func modify_stat(stat_def: Resource, change: int) -> void:
	var stat_type = stat_def.type
	var cost = stat_def.cost_per_point
	
	# Validation: Adding
	if change > 0:
		if inventory_system.coins < cost: return # Not enough money
		inventory_system.coins -= cost
		
	# Validation: Removing
	elif change < 0:
		if get_player_stat(stat_type) <= 0: return # Nothing to refund
		inventory_system.coins += cost
	
	# Update Data
	if not player_stats.has(stat_type): player_stats[stat_type] = 0
	player_stats[stat_type] += change
	
	# Apply to Player
	_apply_single_stat_change(stat_def, change)

func _apply_single_stat_change(stat_def: Resource, change: int) -> void:
	if not player: return
	
	var amount = change * stat_def.value_per_point
	
	match stat_def.type:
		"max_health":
			player.max_health += amount
			player.health = clamp(player.health + amount, 0, player.max_health)
			player.health_changed.emit()
		"max_mana":
			player.max_mana += amount
			player.mana = clamp(player.mana + amount, 0, player.max_mana)
			player.mana_changed.emit()
		"attack":
			# Assuming player has a property for this, otherwise add it to Player.gd
			if "base_damage" in player: player.base_damage += amount
		"defense":
			if "defense_multiplier" in player: player.defense_multiplier += (amount * 0.01) # e.g., 1 point = 1%
		"speed":
			player.movement_speed += amount
		"jump":
			player.jump_velocity += amount # Assuming your Player script handles this logic
		_:
			push_warning("GameManager: Unhandled stat type '%s'" % stat_def.type)

func _reapply_all_stats() -> void:
	"""Loops through saved stats and applies them based on definitions"""
	if not player: return
	
	for stat_def in stat_definitions:
		var points_allocated = get_player_stat(stat_def.type)
		if points_allocated > 0:
			# Apply the TOTAL effect of all points
			_apply_single_stat_change(stat_def, points_allocated)
#endregion
