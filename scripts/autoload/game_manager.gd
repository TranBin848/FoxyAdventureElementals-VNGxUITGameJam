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
signal level_ready()

# --- Inventory & Systems ---
var inventory_system: InventorySystem = null

# --- Stat Storage ---
# Add base stat storage
var player_base_stats: Dictionary = {} # Store original base values ONCE
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
	
	if player and player_base_stats.is_empty():
		_capture_base_stats()

	# Scale Enemies
	get_tree().call_group("enemies", "scale_health", 0.8 + 0.2 * current_level)

	await _handle_checkpoint_or_portal_spawn()
	
	# ✅ Emit signal so level scripts know spawning is complete
	if has_signal("level_ready"):
		level_ready.emit()

func change_stage(stage_path: String, _target_portal_name: String = "") -> void:
	target_portal_name = _target_portal_name
	get_tree().change_scene_to_file(stage_path)

func _capture_base_stats() -> void:
	"""Stores the player's initial stat values on first spawn"""
	if not player: return
	
	player_base_stats = {
		"max_health": player.max_health,
		"max_mana": player.max_mana,
		"base_damage": player.get("base_damage") if "base_damage" in player else 0,
		"defense_multiplier": player.get("defense_multiplier") if "defense_multiplier" in player else 1.0,
		"movement_speed": player.movement_speed,
		"jump_velocity": player.jump_velocity
	}
	print("📊 Base stats captured: ", player_base_stats)

func _handle_checkpoint_or_portal_spawn() -> void:
	"""Unified spawn handler - portals take priority over checkpoints"""
	if not player: return
	
	# 1. Try Portal First (scene transitions)
	if respawn_at_portal():
		print("🚪 Spawned at portal: %s" % target_portal_name)
		return
	
	# 2. Try Checkpoint (saved game)
	if not current_checkpoint_id.is_empty():
		var checkpoint_scene = checkpoint_data.get(current_checkpoint_id, {}).get("stage_path", "")
		
		# Validate checkpoint matches current scene
		if checkpoint_scene == current_stage.scene_file_path:
			await get_tree().create_timer(0.1).timeout
			respawn_at_checkpoint()
			print("💾 Loaded checkpoint: %s" % current_checkpoint_id)
			return
		else:
			print("⚠️ Checkpoint scene mismatch, clearing...")
			clear_checkpoint_data()
	
	# 3. Default: Player spawns at their scene position
	print("🎮 Player spawned at default position")
	
func respawn_at_portal() -> bool:
	if target_portal_name.is_empty() or not current_stage or not player:
		return false
		
	var door = current_stage.find_child(target_portal_name)
	if door:
		player.global_position = door.global_position
		target_portal_name = ""
		return true
	return false

func respawn_at_checkpoint() -> void:
	if current_checkpoint_id.is_empty(): return
	var saved_stage_path := ""
	
	# Get path from memory OR disk
	if checkpoint_data.has(current_checkpoint_id):
		saved_stage_path = checkpoint_data[current_checkpoint_id].get("stage_path", "")
	else:
		var save_file_data = SaveSystem.load_checkpoint_data()
		saved_stage_path = save_file_data.get("stage_path", "")

	# 1. Load Position/Flags
	player.load_state(data.get("player_state", {}))
	
	# 2. ✅ CALCULATE and SET stats (not add!)
	_apply_all_stats_from_base()

	# 3. Restore Inventory
	if inventory_system:
		inventory_system.load_data(data.get("inventory_data", {}))
		
	checkpoint_loading_complete.emit()
	print("✅ Checkpoint restoration complete")
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

func _apply_all_stats_from_base() -> void:
	"""Calculates TOTAL stat values from base + allocated points"""
	if not player or player_base_stats.is_empty(): return
	
	for stat_def in stat_definitions:
		var points_allocated = get_player_stat(stat_def.type)
		var bonus = points_allocated * stat_def.value_per_point
		
		match stat_def.type:
			"max_health":
				player.max_health = player_base_stats.max_health + bonus
				player.health = min(player.health, player.max_health)
				player.health_changed.emit()
			"max_mana":
				player.max_mana = player_base_stats.max_mana + bonus
				player.mana = min(player.mana, player.max_mana)
				player.mana_changed.emit()
			"attack":
				if "base_damage" in player:
					player.base_damage = player_base_stats.base_damage + bonus
			"defense":
				if "defense_multiplier" in player:
					player.defense_multiplier = player_base_stats.defense_multiplier + (bonus * 0.01)
			"speed":
				player.movement_speed = player_base_stats.movement_speed + bonus
			"jump":
				player.jump_velocity = player_base_stats.jump_velocity + bonus
	
	print("📈 Stats applied: %d points allocated" % player_stats.values().reduce(func(a, b): return a + b, 0))

func modify_stat(stat_def: Resource, change: int) -> void:
	var stat_type = stat_def.type
	var cost = stat_def.cost_per_point
	
	# Validation
	if change > 0:
		if inventory_system.coins < cost: return
		inventory_system.coins -= cost
	elif change < 0:
		if get_player_stat(stat_type) <= 0: return
		inventory_system.coins += cost
	
	# Update allocated points
	if not player_stats.has(stat_type): player_stats[stat_type] = 0
	player_stats[stat_type] += change
	
	# ✅ Recalculate from base instead of adding incrementally
	_apply_all_stats_from_base()
#endregion

func player_act(method_name: String, a1=null, a2=null, a3=null, a4=null, a5=null) -> void:
	if not player: return
	if not player.has_method(method_name): return
	
	#player.fsm.change_state(player.fsm.states.actor)
	
	# 1. Collect valid arguments into a real Array
	var args = []
	# We check each argument; if it's not null, we add it to the list
	for val in [a1, a2, a3, a4, a5]:
		if val != null:
			args.append(val)
			
	# 2. Call the function with the reconstructed array
	player.callv(method_name, args)

func collect_wand() -> void:
	if not player: return
	player.equip_weapon(player.WeaponType.WAND)
	player.has_wand = true
