extends Node

#region Configuration & Resources
@export_group("UI & Scenes")
@export var upgrade_popup_scene: PackedScene = preload("res://scenes/ui/upgrade/upgrade_popup.tscn")
@export_group("Stats Data")
@export var stat_definitions: Array[Resource] = [preload("res://resources/stats/max_health.tres"),preload("res://resources/stats/max_mana.tres")] 
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
var current_save_slot_index: int = 1
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
	
	# Timer to detect scene changes (handles transitions smoothly)
	var scene_detector = Timer.new()
	scene_detector.name = "SceneDetector"
	scene_detector.wait_time = 0.05
	scene_detector.autostart = true
	scene_detector.timeout.connect(_on_scene_detector_timeout)
	add_child(scene_detector)
	print("✅ Scene detector timer started")
	
	# Handle initial scene
	await get_tree().process_frame
	print("⏳ Processing initial scene...")
	_on_scene_changed()

func _on_scene_detector_timeout() -> void:
	var current = get_tree().current_scene
	
	# Only trigger if scene actually changed
	if current and current != current_stage:
		print("🔔 Timer detected scene change!")
		print("  From: %s" % (current_stage.scene_file_path if current_stage else "null"))
		print("  To: %s" % current.scene_file_path)
		_on_scene_changed()

func change_stage(stage_path: String, _target_portal_name: String = "") -> void:
	print("🌍 Changing scene to: %s (portal: %s)" % [stage_path, _target_portal_name])
	
	target_portal_name = _target_portal_name
	save_run_state()
	
	get_tree().change_scene_to_file(stage_path)

#region Scene Management
func _on_tree_changed() -> void:
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
	
	# ✅ FIX: AWAIT the spawn handler so it completes before proceeding
	await _handle_checkpoint_or_portal_spawn()
	
	# =========================================================================
	# ✅ Implicit Level Start Checkpoint
	# =========================================================================
	# Now this runs AFTER spawn handling is complete
	if player and not is_loading_from_checkpoint:
		print("🚩 Creating implicit level-start checkpoint...")
		save_checkpoint("auto_level_start")
	# =========================================================================
	
	# ✅ FIX: level_ready now emits AFTER player is fully positioned/restored
	if has_signal("level_ready"):
		level_ready.emit()
		print("✅ Level setup complete - level_ready signal emitted")

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
		respawn_at_portal()
		if is_scene_transition:
			restore_run_state()
			print("✅ Run state restored (after portal attempt)")
		return

	# 2. Checkpoint load (saved game from disk - death or load game)
	if is_loading_from_checkpoint and not current_checkpoint_id.is_empty():
		var checkpoint_scene = checkpoint_data.get(current_checkpoint_id, {}).get("stage_path", "")
		
		# Allow loading if scene matches OR if we are forcing a reload
		if checkpoint_scene == current_stage.scene_file_path:
			# Wait for the physics engine to initialize the new map fully
			await get_tree().physics_frame
			await get_tree().physics_frame
			respawn_at_checkpoint()
			is_loading_from_checkpoint = false
			print("💾 Loaded from checkpoint: %s" % current_checkpoint_id)
			return
		else:
			print("⚠️ Checkpoint scene mismatch")
			print("  Expected: %s" % checkpoint_scene)
			print("  Current: %s" % current_stage.scene_file_path)
			is_loading_from_checkpoint = false
	
	# 3. Scene transition (no portal specified, just keeping data)
	if is_scene_transition:
		restore_run_state()
		print("🎮 Run state restored (no portal specified)")
		return
	
	# 4. Fresh start
	print("🎮 Player spawned at default position (new game)")

# ============================================================================
# Respawn Logic
# ============================================================================

func respawn_at_portal() -> bool:
	if target_portal_name.is_empty() or not current_stage or not player:
		return false
	
	var door = null
	
	# Search Priority: Direct Child -> Portals Group -> Spawn Points Group
	door = current_stage.find_child(target_portal_name, true, false)
	if not door:
		for p in get_tree().get_nodes_in_group("portals"):
			if p.name == target_portal_name: door = p; break
	if not door:
		for sp in get_tree().get_nodes_in_group("spawn_points"):
			if sp.name == target_portal_name: door = sp; break
	
	if door:
		player.global_position = door.global_position
		target_portal_name = "" 
		return true
	
	print("  ❌ Portal '%s' not found, staying at default spawn" % target_portal_name)
	return false

func respawn_at_checkpoint() -> void:
	if current_checkpoint_id.is_empty(): return
	
	var data = checkpoint_data.get(current_checkpoint_id, {})
	if data.is_empty() or not player: return
	
	# 1. Load Position/Flags
	player.load_state(data.get("player_state", {}))
	
	if data.has("player_stats"):
		player_stats = data.get("player_stats", {}).duplicate()
		
	if data.has("player_base_stats"):
		player_base_stats = data.get("player_base_stats", {}).duplicate()
	
	# 2. Recalculate Stats (Tính lại Max HP dựa trên upgrade)
	_apply_all_stats_from_base()
	
	# 3. XỬ LÝ MÁU
	player.health = player.max_health
	player.mana = player.max_mana
	
	player.health_changed.emit()
	player.mana_changed.emit()

	# 4. Restore Inventory
	if inventory_system:
		inventory_system.load_data(data.get("inventory_data", {}))
	
	save_run_state()
	checkpoint_loading_complete.emit()
	print("✅ Checkpoint restoration complete")
#endregion

#region Run State (Session Persistence)
func save_run_state() -> void:
	if not player: return
	
	current_run_state = {
		"player_state": player.save_state(),
		"inventory_data": inventory_system.save_data() if inventory_system else {},
		"player_stats": player_stats.duplicate(),
		"player_base_stats": player_base_stats.duplicate(),
		"health": player.health,
		"max_health": player.max_health,
		"mana": player.mana,
		"max_mana": player.max_mana,
		"current_level": current_level,
		"skill_tree": SkillTreeManager.save_data(),
		"guide_data": GameProgressManager.get_save_data()
	}

func restore_run_state() -> void:
	if current_run_state.is_empty() or not player: return
	
	var current_position = player.global_position
	player.load_state(current_run_state.get("player_state", {}))
	player.global_position = current_position
	
	if current_run_state.has("guide_data"):
		GameProgressManager.load_save_data(current_run_state["guide_data"])
	
	if inventory_system:
		inventory_system.load_data(current_run_state.get("inventory_data", {}))
	
	if current_run_state.has("player_base_stats"):
		player_base_stats = current_run_state["player_base_stats"].duplicate()
	
	player_stats = current_run_state.get("player_stats", {}).duplicate()
	
	_apply_all_stats_from_base()
	
	if current_run_state.has("health"):
		player.health = current_run_state["health"]
		if player.health > player.max_health: player.health = player.max_health 
		player.health_changed.emit()
		
	if current_run_state.has("mana"):
		player.mana = current_run_state["mana"]
		if player.mana > player.max_mana: player.mana = player.max_mana
		player.mana_changed.emit()
	
	SkillTreeManager.load_data(current_run_state.get("skill_tree", {}))
	current_level = current_run_state.get("current_level", 0)

func clear_run_state() -> void:
	current_run_state.clear()
	print("🗑️ Run state cleared")
#endregion

#region Save & Load System (Disk Persistence)
func save_checkpoint(checkpoint_id: String) -> void:
	if not player: return

	current_checkpoint_id = checkpoint_id
	checkpoint_changed.emit(checkpoint_id)

	var player_state_dict = player.save_state()
	var inventory_data = inventory_system.save_data() if inventory_system else {}
	
	checkpoint_data.clear()
	checkpoint_data[checkpoint_id] = {
		"player_state": player_state_dict,
		"inventory_data": inventory_data,
		"player_stats": player_stats.duplicate(),
		"player_base_stats": player_base_stats.duplicate(),
		"stage_path": current_stage.scene_file_path,
	}

	SaveSystem.save_game(
		current_save_slot_index, # <--- KEY CHANGE
		checkpoint_id,
		checkpoint_data[checkpoint_id],
		current_stage.scene_file_path,
		SkillTreeManager.save_data(),
		GameProgressManager.get_save_data()
	)
	print("💾 Checkpoint saved: %s" % checkpoint_id)

func load_checkpoint_data() -> void:
	var save_data = SaveSystem.load_game(current_save_slot_index)
	if save_data.is_empty(): 
		clear_run_state()
		return
	
	is_loading_from_checkpoint = true
	
	current_checkpoint_id = save_data.get("checkpoint_id", "")
	var loaded_player_data = save_data.get("player", {})
	
	if inventory_system:
		inventory_system.load_data(loaded_player_data.get("inventory_data", {}))
		
	if loaded_player_data.has("guide_data"):
		GameProgressManager.load_save_data(loaded_player_data["guide_data"])
		
	if loaded_player_data.has("player_base_stats"):
		player_base_stats = loaded_player_data["player_base_stats"].duplicate()

	SkillTreeManager.load_data(save_data.get("skill_tree", {}))
	player_stats = loaded_player_data.get("player_stats", {}).duplicate()

	if not current_checkpoint_id.is_empty():
		checkpoint_data.clear()
		checkpoint_data[current_checkpoint_id] = loaded_player_data
	
	print("📂 Checkpoint data loaded from disk")

func clear_checkpoint_data() -> void:
	current_checkpoint_id = ""
	checkpoint_data.clear()
	player_stats.clear()
	SaveSystem.delete_slot(current_save_slot_index)
	print("🗑️ Checkpoint data cleared")
#endregion

#region Player Death & Respawn Handling
func on_player_death() -> void:
	print("\n💀 ============ PLAYER DEATH ============")
	print("Current checkpoint: %s" % current_checkpoint_id)
	print("Checkpoint data exists: %s" % (not checkpoint_data.is_empty()))
	
	# 1. Clear run state (prevents carrying over dead state)
	clear_run_state()
	
	# 2. Check for valid checkpoint
	if not current_checkpoint_id.is_empty():
		var saved_stage_path = checkpoint_data.get(current_checkpoint_id, {}).get("stage_path", "")
		
		print("Saved stage path: %s" % saved_stage_path)
		print("Current stage path: %s" % (current_stage.scene_file_path if current_stage else "null"))
		
		# 3. ✅ Set flag so _on_scene_changed calls respawn_at_checkpoint()
		is_loading_from_checkpoint = true
		
		if not saved_stage_path.is_empty():
			print("🔄 Reloading scene from checkpoint...")
			get_tree().change_scene_to_file(saved_stage_path)
		else:
			print("⚠️ Checkpoint path missing, reloading current scene")
			if current_stage:
				get_tree().change_scene_to_file(current_stage.scene_file_path)
			else:
				print("❌ ERROR: No current_stage reference!")
	else:
		print("⚠️ No checkpoint found! Restarting level with defaults.")
		if current_stage:
			get_tree().change_scene_to_file(current_stage.scene_file_path)
		else:
			print("❌ ERROR: No current_stage reference!")
	
	print("========================================\n")
#endregion

#region New Game & Load Game
# 2. UPDATED NEW GAME LOGIC
func start_new_game(slot_index: int) -> void:
	print("🎮 Starting New Game on Slot %d" % slot_index)
	
	current_save_slot_index = slot_index
	
	# Optional: Delete old data if user overwrites a slot
	SaveSystem.delete_slot(slot_index) 
	
	clear_checkpoint_data()
	clear_run_state()
	get_tree().change_scene_to_file("res://levels/level_0/level_0.tscn")

# 3. UPDATED LOAD LOGIC
func load_saved_game(slot_index: int) -> void:
	print("📂 Loading Game from Slot %d" % slot_index)
	
	current_save_slot_index = slot_index

	# 1. Load data from disk into memory variables
	# This populates 'checkpoint_data', 'player_stats', 'is_loading_from_checkpoint = true', etc.
	load_checkpoint_data()
	
	# 2. Validation: Did we actually get a checkpoint ID?
	if current_checkpoint_id.is_empty() or not checkpoint_data.has(current_checkpoint_id):
		print("⚠️ Error: Save loaded but no checkpoint data found. Starting New Game.")
		start_new_game(slot_index)
		return
	
	# 3. Retrieve the scene path
	# We dig into the data we just loaded into 'checkpoint_data'
	var saved_scene_path = checkpoint_data[current_checkpoint_id].get("stage_path", "")
	
	if saved_scene_path.is_empty():
		print("⚠️ Error: Checkpoint found but 'stage_path' is missing!")
		return

	# 4. Change Scene
	# Since 'is_loading_from_checkpoint' is now true, _on_scene_changed() will
	# automatically handle placing the player and restoring stats once the scene finishes loading.
	print("🔄 Transitioning to saved scene: %s" % saved_scene_path)
	get_tree().change_scene_to_file(saved_scene_path)
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

func modify_stat(stat_def: Resource, change: int) -> void:
	var stat_type = stat_def.type
	var cost = stat_def.cost_per_point
	
	if change > 0:
		if inventory_system.coins < cost: return
		inventory_system.use_coin(cost)
	elif change < 0:
		if get_player_stat(stat_type) <= 0: return
		inventory_system.add_coin(cost)
	
	if not player_stats.has(stat_type): player_stats[stat_type] = 0
	player_stats[stat_type] += change
	
	_apply_all_stats_from_base()
#endregion

#region Cutscene & Actor System
func player_act(method_name: String, a1=null, a2=null, a3=null, a4=null, a5=null) -> void:
	if not player: return
	if not player.has_method(method_name): return
	
	var args = []
	for val in [a1, a2, a3, a4, a5]:
		if val != null: args.append(val)
			
	player.callv(method_name, args)
