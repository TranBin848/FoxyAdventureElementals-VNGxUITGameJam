extends Node

# --- Portal & Stage ---
var target_portal_name: String = ""
var current_stage: Node = null
var current_level: int = 0
var player: Player = null
var skill_bar: SkillBar = null
var minimap: Minimap = null

# --- Checkpoint system ---
var current_checkpoint_id: String = ""
var checkpoint_data: Dictionary = {}
signal checkpoint_changed(new_checkpoint_id: String)

# --- Player states ---
var has_blade: bool = false
var has_wand: bool = false
var isReloadScene: bool = false

# --- Inventory system ---
var inventory_system: InventorySystem = null

func _ready() -> void:
	get_tree().connect("current_scene_changed", _on_scene_changed)
	inventory_system = InventorySystem.new()
	add_child(inventory_system)
	load_checkpoint_data()
	_on_scene_changed()

# --- Scene change ---
func _on_scene_changed() -> void:
	current_stage = get_tree().current_scene

	# Nếu không có stage (menu, loading, ...) thì bỏ qua
	if current_stage == null:
		return

	# Tìm Player
	player = current_stage.find_child("Player", true, false)

	# Scale enemy max health based on level
	get_tree().get_nodes_in_group("enemies").map(
		func(e): 
			e.max_health *= (0.8 + 0.2 * current_level)
			e.health = e.max_health
	)

	var skillbarroot = current_stage.find_child("SkillBarUI", true, false)
	if skillbarroot:
		skill_bar = skillbarroot.get_node("MarginContainer/SkillBar")

	# --- KIỂM TRA CHECKPOINT CÓ CÒN HỢP LỆ KHÔNG ---
	if not current_checkpoint_id.is_empty():
		var saved_stage_path := ""
		if checkpoint_data.has(current_checkpoint_id):
			# checkpoint từ session hiện tại
			saved_stage_path = checkpoint_data[current_checkpoint_id].get("stage_path", "")
		else:
			# checkpoint được load từ SaveSystem (player_data)
			var save_file_data := SaveSystem.load_checkpoint_data()
			saved_stage_path = save_file_data.get("stage_path", "")

		# Nếu scene hiện tại KHÁC scene đã lưu -> XÓA CHECKPOINT + FILE SAVE
		if current_stage.scene_file_path != saved_stage_path:
			clear_checkpoint_data() # reset toàn bộ
		else:
			# Nếu scene giống -> respawn (chỉ khi có player)
			if player:
				await get_tree().create_timer(0.1).timeout
				respawn_at_checkpoint()

# --- Stage change ---
func change_stage(stage_path: String, _target_portal_name: String = "") -> void:
	target_portal_name = _target_portal_name
	get_tree().change_scene_to_file(stage_path)

# --- Portal respawn ---
func respawn_at_portal() -> bool:
	if not target_portal_name.is_empty() and current_stage:
		var door = current_stage.find_child(target_portal_name)
		if door and player:
			player.global_position = door.global_position
			target_portal_name = ""
			return true
	return false

# --- SAVE SYSTEM ---
func save_checkpoint(checkpoint_id: String) -> void:
	if not player:
		return

	# Luôn chỉ giữ checkpoint mới nhất
	current_checkpoint_id = checkpoint_id
	checkpoint_changed.emit(checkpoint_id)

	var player_state_dict = player.save_state()
	var inventory_data = inventory_system.save_data() if inventory_system else {}

	# Ghi đè dữ liệu cho checkpoint hiện tại
	checkpoint_data.clear()
	checkpoint_data[checkpoint_id] = {
		"player_state": player_state_dict,
		"has_blade": player.has_blade,
		"has_wand": player.has_wand,
		"inventory_data": inventory_data,
		"stage_path": current_stage.scene_file_path
	}

	SaveSystem.save_checkpoint_data(
		checkpoint_id,
		checkpoint_data[checkpoint_id],
		current_stage.scene_file_path,
		SkillTreeManager.save_data()
	)

# --- Respawn ---
func respawn_at_checkpoint() -> void:
	if current_checkpoint_id.is_empty():
		return

	var checkpoint_info = checkpoint_data.get(current_checkpoint_id, {})
	if checkpoint_info.is_empty():
		return

	if player:
		player.load_state(checkpoint_info.get("player_state", {}))
		player.has_blade = checkpoint_info.get("has_blade", false)
		player.has_wand = checkpoint_info.get("has_wand", false)

		if checkpoint_info.has("inventory_data") and inventory_system:
			inventory_system.load_data(checkpoint_info["inventory_data"])

		if player.has_blade:
			player.collected_blade()

func has_checkpoint() -> bool:
	return not current_checkpoint_id.is_empty()

# --- LOAD SYSTEM ---
func load_checkpoint_data() -> void:
	var save_data = SaveSystem.load_checkpoint_data()
	if save_data.is_empty():
		return

	current_checkpoint_id = save_data.get("checkpoint_id", "")
	var player_data = save_data.get("player", {})
	var inventory_data = save_data.get("inventory_data", {})
	var skill_tree_data = save_data.get("skill_tree", {})
	var stage_path = save_data.get("stage_path", "")

	if inventory_data and inventory_system:
		inventory_system.load_data(inventory_data)

	SkillTreeManager.load_data(skill_tree_data)

	# Chỉ lưu lại checkpoint mới nhất
	if not current_checkpoint_id.is_empty():
		checkpoint_data.clear()
		player_data["stage_path"] = stage_path
		checkpoint_data[current_checkpoint_id] = player_data

func clear_checkpoint_data() -> void:
	current_checkpoint_id = ""
	checkpoint_data.clear()
	has_blade = false
	has_wand = false
	SaveSystem.delete_save_file()

func collect_blade() -> void:
	if has_blade:
		return
	has_blade = true
	if player:
		player.collected_blade()

func collect_wand() -> void:
	if has_wand:
		return
	has_wand = true
	if player:
		player.collected_wand()

func scale_health() -> void:
	get_tree().call_group("enemies", "scale_health", 0.8 + 0.2 * current_level)
