extends Node

#region Configuration & Resources
@export_group("UI & Scenes")
@export var upgrade_popup_scene: PackedScene = preload("res://scenes/ui/upgrade/upgrade_popup.tscn")
@export_group("Stats Data")
@export var stat_definitions: Array[Resource] = [preload("res://resources/stats/max_health.tres"),preload("res://resources/stats/max_health.tres")] # Drag ALL your PlayerStat .tres files here!
#endregion

#region State Variables
# --- Portal & Stage ---
var target_portal_name: String = ""
var current_stage: Node = null
var current_level: int = 0
var player: Player = null
var skill_bar: SkillBar = null
var minimap: Minimap = null

# --- Checkpoint & Save (Disk Persistence) ---
var current_checkpoint_id: String = ""
var checkpoint_data: Dictionary = {}
signal checkpoint_changed(new_checkpoint_id: String)
signal checkpoint_loading_complete()
signal level_ready()

# --- Run State (Session Persistence) ---
var current_run_state: Dictionary = {}
var is_loading_from_checkpoint: bool = false # Flag to differentiate load types

# --- Inventory & Systems ---
var inventory_system: InventorySystem = null

# --- Stat Storage ---
var player_base_stats: Dictionary = {} # Store original base values ONCE
var player_stats: Dictionary = {} 
#endregion

func _ready() -> void:
	print("\n🎮 GameManager initializing...")
	
	# Initialize Systems
	inventory_system = InventorySystem.new()
	add_child(inventory_system)
	print("✅ Inventory system initialized")
	
	# ✅ FIX: Use Timer instead of _process()
	# Timers continue running during scene transitions!
	var scene_detector = Timer.new()
	scene_detector.name = "SceneDetector"
	scene_detector.wait_time = 0.05  # Check every 50ms
	scene_detector.autostart = true
	scene_detector.timeout.connect(_on_scene_detector_timeout)
	add_child(scene_detector)
	print("✅ Scene detector timer started")
	
	# Handle initial scene
	await get_tree().process_frame
	print("⏳ Processing initial scene...")
	_on_scene_changed()

# ✅ NEW: Timer callback that checks for scene changes
func _on_scene_detector_timeout() -> void:
	var current = get_tree().current_scene
	
	# Only trigger if scene actually changed
	if current and current != current_stage:
		print("🔔 Timer detected scene change!")
		print("  From: %s" % (current_stage.scene_file_path if current_stage else "null"))
		print("  To: %s" % current.scene_file_path)
		_on_scene_changed()

# Keep change_stage() simple:
func change_stage(stage_path: String, _target_portal_name: String = "") -> void:
	print("🌍 Changing scene to: %s (portal: %s)" % [stage_path, _target_portal_name])
	
	target_portal_name = _target_portal_name
	save_run_state()
	
	# Just change the scene - timer will detect it
	get_tree().change_scene_to_file(stage_path)

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
	if not player: return
	
	print("🎯 Spawn handler called:")
	var is_scene_transition = not current_run_state.is_empty() and not is_loading_from_checkpoint
	
	# 1. Try Portal
	if not target_portal_name.is_empty():
		respawn_at_portal() # Sets position if found
		
		if is_scene_transition:
			restore_run_state() # Never changes position
			print("✅ Run state restored (after portal attempt)")
		return

	# 2. Checkpoint load (saved game from disk - death or load game)
	if is_loading_from_checkpoint and not current_checkpoint_id.is_empty():
		var checkpoint_scene = checkpoint_data.get(current_checkpoint_id, {}).get("stage_path", "")
		
		if checkpoint_scene == current_stage.scene_file_path:
			await get_tree().create_timer(0.1).timeout
			respawn_at_checkpoint()
			is_loading_from_checkpoint = false
			print("💾 Loaded from checkpoint: %s" % current_checkpoint_id)
			return
		else:
			print("⚠️ Checkpoint scene mismatch")
			print("  Expected: %s" % checkpoint_scene)
			print("  Current: %s" % current_stage.scene_file_path)
			clear_checkpoint_data()
			is_loading_from_checkpoint = false
	
	# 3. Scene transition
	if is_scene_transition:
		restore_run_state() # Never changes position
		print("🎮 Run state restored (no portal specified)")
		return
	
	# 4. Fresh start
	print("🎮 Player spawned at default position (new game)")

# ============================================================================
# Enhanced respawn_at_portal() - Better error handling
# ============================================================================

func respawn_at_portal() -> bool:
	"""
	Attempts to position player at target portal.
	Returns true if successful, false if portal not found.
	Note: This only handles positioning, NOT data restoration.
	"""
	if target_portal_name.is_empty() or not current_stage or not player:
		return false
	
	print("🔍 Searching for portal: '%s'" % target_portal_name)
	
	# Try multiple search methods
	var door = null
	
	# Method 1: Direct recursive search
	door = current_stage.find_child(target_portal_name, true, false)
	if door:
		print("  ✅ Found via find_child: %s" % door.name)
	
	# Method 2: Search in portals group
	if not door:
		var portals = get_tree().get_nodes_in_group("portals")
		for p in portals:
			if p.name == target_portal_name:
				door = p
				print("  ✅ Found via group 'portals': %s" % door.name)
				break
	
	# Method 3: Search in spawn_points group
	if not door:
		var spawn_points = get_tree().get_nodes_in_group("spawn_points")
		for sp in spawn_points:
			if sp.name == target_portal_name or (sp.has_method("get_marker_id") and sp.get_marker_id() == target_portal_name):
				door = sp
				print("  ✅ Found via group 'spawn_points': %s" % door.name)
				break
	
	# Position player if door found
	if door:
		var old_pos = player.global_position
		player.global_position = door.global_position
		print("  📍 Player moved: %s → %s" % [old_pos, door.global_position])
		target_portal_name = "" # Clear for next use
		return true
	
	# Portal not found - log but don't fail the transition
	print("  ❌ Portal '%s' not found in scene" % target_portal_name)
	print("  ℹ️  Player will stay at current position")
	return false

func respawn_at_checkpoint() -> void:
	"""Enhanced checkpoint respawn"""
	if current_checkpoint_id.is_empty(): return
	
	var data = checkpoint_data.get(current_checkpoint_id, {})
	if data.is_empty() or not player: return
	
	# 1. Load Position/Flags
	player.load_state(data.get("player_state", {}))
	
	# 2. ✅ CALCULATE and SET stats (not add!)
	_apply_all_stats_from_base()

	# 3. Restore Inventory
	if inventory_system:
		inventory_system.load_data(data.get("inventory_data", {}))
	
	# ✅ Update run state to match checkpoint
	save_run_state()
	
	checkpoint_loading_complete.emit()
	print("✅ Checkpoint restoration complete")
#endregion

#region Run State (Session Persistence)
func save_run_state() -> void:
	"""Saves current play session state before scene change"""
	if not player: return
	
	current_run_state = {
		"player_state": player.save_state(),
		"inventory_data": inventory_system.save_data() if inventory_system else {},
		"player_stats": player_stats.duplicate(),
		"health": player.health,
		"max_health": player.max_health,
		"mana": player.mana,
		"max_mana": player.max_mana,
		"current_level": current_level,
		"skill_tree": SkillTreeManager.save_data()
	}
	print("💾 Run state saved")

func restore_run_state() -> void:
	"""Restores session state but never restores position"""
	if current_run_state.is_empty() or not player: return
	
	# Save where player currently is (their scene spawn position)
	var current_position = player.global_position
	
	# Restore everything including position
	player.load_state(current_run_state.get("player_state", {}))
	
	# Immediately reset position to where they were
	player.global_position = current_position
	
	# Restore everything else
	player.health = current_run_state.get("health", player.max_health)
	player.max_health = current_run_state.get("max_health", player.max_health)
	player.mana = current_run_state.get("mana", player.max_mana)
	player.max_mana = current_run_state.get("max_mana", player.max_mana)
	player.health_changed.emit()
	player.mana_changed.emit()
	
	if inventory_system:
		inventory_system.load_data(current_run_state.get("inventory_data", {}))
	
	player_stats = current_run_state.get("player_stats", {}).duplicate()
	_apply_all_stats_from_base()
	
	SkillTreeManager.load_data(current_run_state.get("skill_tree", {}))
	
	current_level = current_run_state.get("current_level", 0)
	print("✅ Run state restored (position preserved)")

func clear_run_state() -> void:
	"""Clear run state (call when starting new game or dying)"""
	current_run_state.clear()
	print("🗑️ Run state cleared")
#endregion

#region Save & Load System (Disk Persistence)
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
	
	print("💾 Checkpoint saved: %s" % checkpoint_id)

func load_checkpoint_data() -> void:
	"""Load checkpoint from disk - call this on game start"""
	var save_data = SaveSystem.load_checkpoint_data()
	if save_data.is_empty(): 
		clear_run_state() # Start fresh
		return
	
	is_loading_from_checkpoint = true # ✅ Set flag so we know to load checkpoint
	
	current_checkpoint_id = save_data.get("checkpoint_id", "")
	var loaded_player_data = save_data.get("player", {})
	
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
	
	print("📂 Checkpoint data loaded from disk")

func clear_checkpoint_data() -> void:
	current_checkpoint_id = ""
	checkpoint_data.clear()
	player_stats.clear()
	SaveSystem.delete_save_file()
	print("🗑️ Checkpoint data cleared")
#endregion

#region Player Death & Respawn Handling
func on_player_death() -> void:
	"""Call this when player dies - respawns at last checkpoint"""
	print("💀 Player died")
	
	# Clear run state so they respawn from checkpoint
	clear_run_state()
	
	# Load the checkpoint scene
	if not current_checkpoint_id.is_empty():
		var saved_stage_path = checkpoint_data.get(current_checkpoint_id, {}).get("stage_path", "")
		if not saved_stage_path.is_empty():
			is_loading_from_checkpoint = true
			get_tree().change_scene_to_file(saved_stage_path)
		else:
			print("⚠️ Checkpoint has no valid stage path!")
	else:
		print("⚠️ No checkpoint to respawn from!")
		# Optionally: Return to main menu or restart from beginning
		# get_tree().change_scene_to_file("res://scenes/ui/main_menu.tscn")
#endregion

#region New Game & Load Game (Main Menu Functions)
func start_new_game(starting_scene: String = "res://levels/level_0/level_0.tscn") -> void:
	"""Start a completely fresh game - call from main menu"""
	print("🎮 Starting new game")
	
	# Clear everything
	clear_checkpoint_data()
	clear_run_state()
	current_level = 0
	
	# Reset systems
	#if inventory_system:
		#inventory_system.clear()
	#SkillTreeManager.reset()
	
	# Load starting scene
	get_tree().change_scene_to_file(starting_scene)

func load_saved_game() -> void:
	"""Load saved game from disk - call from main menu"""
	print("📂 Loading saved game")
	
	# Load checkpoint data
	load_checkpoint_data()
	
	# Get the scene to load
	var save_data = SaveSystem.load_checkpoint_data()
	var saved_scene = save_data.get("stage_path", "")
	
	if not saved_scene.is_empty():
		# This will trigger respawn_at_checkpoint in _handle_checkpoint_or_portal_spawn
		get_tree().change_scene_to_file(saved_scene)
	else:
		print("⚠️ No valid save file found!")
		start_new_game() # Fallback to new game
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

#region Cutscene & Actor System
func player_act(method_name: String, a1=null, a2=null, a3=null, a4=null, a5=null) -> void:
	if not player: return
	if not player.has_method(method_name): return
	
	# 1. Collect valid arguments into a real Array
	var args = []
	for val in [a1, a2, a3, a4, a5]:
		if val != null:
			args.append(val)
			
	# 2. Call the function with the reconstructed array
	player.callv(method_name, args)

func collect_wand() -> void:
	if not player: return
	player.equip_weapon(player.WeaponType.WAND)
	player.has_wand = true
#endregion
