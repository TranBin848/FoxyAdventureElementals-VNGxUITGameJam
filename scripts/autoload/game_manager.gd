extends Node

# --- Portal & Stage ---
var target_portal_name: String = ""
var current_stage: Node = null
var player: Player = null

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
	# Load checkpoint khi mở game
	load_checkpoint_data()
	# Theo dõi thay đổi scene để tự khôi phục trạng thái
	get_tree().connect("current_scene_changed", Callable(self, "_on_scene_changed"))
	
	# Init inventory system
	inventory_system = InventorySystem.new()
	add_child(inventory_system)
#
	## Theo dõi thay đổi scene để tự khôi phục trạng thái
	#get_tree().connect("current_scene_changed", Callable(self, "_on_scene_changed"))


# --- Khi đổi scene ---
func _on_scene_changed() -> void:
	current_stage = get_tree().current_scene
	player = current_stage.find_child("Player", true, false)
	
	if not player:
		print("⚠️ Không tìm thấy Player trong scene mới.")
		return
	else:
		print("Đã tìm thấy player")
	# Nếu có checkpoint → khôi phục trạng thái
	if current_checkpoint_id in checkpoint_data:
		var checkpoint_info = checkpoint_data[current_checkpoint_id]
		player.health = checkpoint_info.get("health", player.max_health)
		player.has_blade = checkpoint_info.get("has_blade", false)
		player.load_state(checkpoint_info.get("player_state", {}))

		# Khôi phục inventory nếu có
		if checkpoint_info.has("inventory_data") and inventory_system:
			inventory_system.load_data(checkpoint_info["inventory_data"])
			print("👜 Inventory đã được khôi phục từ checkpoint")
		
		if player.has_blade:
			player.collected_blade()

		print("✅ Player đã được khôi phục từ checkpoint:", current_checkpoint_id)
	else:
		print("ℹ️ Không có dữ liệu checkpoint cho scene này.")


# --- Chuyển stage ---
func change_stage(stage_path: String, _target_portal_name: String = "") -> void:
	target_portal_name = _target_portal_name
	get_tree().change_scene_to_file(stage_path)


# --- Gọi từ Dialogic ---
func call_from_dialogic(msg: String = ""):
	print("📜 Call from dialogic:", msg)


# --- Dịch chuyển qua cổng ---
func respawn_at_portal() -> bool:
	if not target_portal_name.is_empty() and current_stage:
		var door = current_stage.find_child(target_portal_name)
		if door and player:
			player.global_position = door.global_position
			target_portal_name = ""
			return true
	return false


# --- Checkpoint System ---
func save_checkpoint(checkpoint_id: String) -> void:
	if not player:
		print("⚠️ Player not found when saving checkpoint")
		return

	current_checkpoint_id = checkpoint_id
	emit_signal("checkpoint_changed", checkpoint_id)
	
	var player_state_dict: Dictionary = player.save_state()
	var inventory_data = inventory_system.save_data() if inventory_system else {}
	
	checkpoint_data[checkpoint_id] = {
		"player_state": player_state_dict,
		"stage_path": current_stage.scene_file_path,
		"health": player.health,
		"has_blade": player.has_blade,
		"inventory_data": inventory_data
	}
	
	print("✅ Checkpoint saved:", checkpoint_id)
	
	# Ghi xuống file thật
	SaveSystem.save_checkpoint_data(
		checkpoint_id,
		checkpoint_data[checkpoint_id],
		current_stage.scene_file_path
	)


func load_checkpoint(checkpoint_id: String) -> Dictionary:
	if checkpoint_id in checkpoint_data:
		return checkpoint_data[checkpoint_id]
	return {}


# --- Hồi sinh từ checkpoint ---
func respawn_at_checkpoint() -> void:
	if current_checkpoint_id.is_empty():
		print("⚠️ No checkpoint available")
		return

	var checkpoint_info = checkpoint_data.get(current_checkpoint_id, {})
	if checkpoint_info.is_empty():
		print("⚠️ Checkpoint data not found")
		return

	var checkpoint_stage = checkpoint_info.get("stage_path", "")
	if current_stage.scene_file_path != checkpoint_stage and not checkpoint_stage.is_empty():
		print("🌀 Changing stage to checkpoint scene...")
		change_stage(checkpoint_stage, "")
		return

	if player:
		player.load_state(checkpoint_info.get("player_state", {}))
		player.health = checkpoint_info.get("health", player.max_health)
		player.has_blade = checkpoint_info.get("has_blade", false)
		
		# Khôi phục inventory
		if checkpoint_info.has("inventory_data") and inventory_system:
			inventory_system.load_data(checkpoint_info["inventory_data"])
			print("👜 Inventory loaded from checkpoint")
		
		if player.has_blade:
			player.collected_blade()

		print("✅ Player respawned at checkpoint:", current_checkpoint_id)
	else:
		print("⚠️ Player not found for respawn")


func has_checkpoint() -> bool:
	return not current_checkpoint_id.is_empty()


# --- Persistent Save ---
func load_checkpoint_data() -> void:
	var save_data = SaveSystem.load_checkpoint_data()
	if save_data.is_empty():
		print("⚠️ No checkpoint file found.")
		return

	current_checkpoint_id = save_data.get("checkpoint_id", "")
	var player_data = save_data.get("player", {})
	var stage_path = save_data.get("stage_path", "")
	var inventory_data = save_data.get("inventory_data", {})

	if not current_checkpoint_id.is_empty():
		checkpoint_data[current_checkpoint_id] = player_data

		if not stage_path.is_empty():
			print("🗺️ Loading checkpoint scene:", stage_path)
			change_stage(stage_path)
		else:
			print("✅ Checkpoint loaded but no stage path found.")
		
		# Khôi phục inventory ngoài scene load
		if inventory_data and inventory_system:
			inventory_system.load_data(inventory_data)
			print("👜 Inventory loaded from save_data")
	else:
		print("✅ Checkpoint data loaded, but no active checkpoint.")


func clear_checkpoint_data() -> void:
	current_checkpoint_id = ""
	checkpoint_data.clear()
	SaveSystem.delete_save_file()
	print("🧹 All checkpoint data cleared.")


# --- Nhặt blade ---
func collect_blade() -> void:
	if has_blade:
		print("⚔️ Player already has the blade.")
		return

	has_blade = true
	print("⚔️ Player collected the blade!")

	if player:
		player.collected_blade()

func collect_wand() -> void:
	if has_wand:
		return
		
	has_wand = true
	
	if player:
		player.collected_wand()
	
