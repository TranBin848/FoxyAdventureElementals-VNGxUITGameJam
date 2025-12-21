extends Node

# --- Portal & Stage ---
var target_portal_name: String = ""
var current_stage: Node = null
var current_level: int = 0
var player: Player = null
var skill_bar: SkillBar = null

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

#var logger: logger = Console#logger.new()

func _ready() -> void:
	get_tree().connect("current_scene_changed", _on_scene_changed)
	inventory_system = InventorySystem.new()
	add_child(inventory_system)
	load_checkpoint_data()

# --- Scene change (ĐÃ SỬA LOGIC) ---
func _on_scene_changed() -> void:
	current_stage = get_tree().current_scene
	
	# Tìm Player trước để xác định đây có phải là màn chơi không (tránh reset ở Menu)
	player = current_stage.find_child("Player", true, false)
	
	# Scale enemy max health based on level
	get_tree().get_nodes_in_group("enemies").map(func(e): e.max_health *= (0.8 + 0.2 * current_level); e.health = e.max_health)
	
	var skillbarroot = current_stage.find_child("SkillBarUI", true, false)
	if skillbarroot:
		skill_bar = skillbarroot.get_node("MarginContainer/SkillBar")
	
	# --- LOGIC KIỂM TRA CHECKPOINT MỚI ---
	if not current_checkpoint_id.is_empty() and player:
		var checkpoint_info = checkpoint_data.get(current_checkpoint_id, {})
		var saved_stage_path = checkpoint_info.get("stage_path", "")
		
		# Nếu đường dẫn scene hiện tại KHÁC với đường dẫn trong save -> Reset (coi như không có checkpoint)
		if current_stage.scene_file_path != saved_stage_path:
			# logger.info("⚠️ Scene khác nhau (%s vs %s). Reset checkpoint." % [current_stage.scene_file_path, saved_stage_path])
			current_checkpoint_id = "" # <--- THAY ĐỔI: Reset ID để không respawn
		else:
			# Nếu cùng level thì mới respawn
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
	if not player: return

	current_checkpoint_id = checkpoint_id
	checkpoint_changed.emit(checkpoint_id)
	
	var player_state_dict = player.save_state()
	var inventory_data = inventory_system.save_data() if inventory_system else {}
	
	checkpoint_data[checkpoint_id] = {
		"player_state": player_state_dict,
		"has_blade": player.has_blade,
		"has_wand": player.has_wand,
		"inventory_data": inventory_data,
		"stage_path": current_stage.scene_file_path 
	}
	
	# LƯU SKILL TREE + SKILL BAR + COINS
	SaveSystem.save_checkpoint_data(
		checkpoint_id,
		checkpoint_data[checkpoint_id],
		current_stage.scene_file_path,
		SkillTreeManager.save_data() # <--- Dùng hàm mới này
	)
# --- Respawn (ĐÃ SỬA LOGIC) ---
func respawn_at_checkpoint() -> void:
	if current_checkpoint_id.is_empty(): return

	var checkpoint_info = checkpoint_data.get(current_checkpoint_id, {})
	if checkpoint_info.is_empty(): return
	
	# <--- THAY ĐỔI: Đã xóa đoạn code check "if scene != checkpoint_stage then change_stage"
	# Vì logic reset đã được xử lý ở _on_scene_changed rồi.
	# Hàm này bây giờ chỉ thuần túy set vị trí và trạng thái Player.

	if player:
		player.load_state(checkpoint_info.get("player_state", {}))
		player.has_blade = checkpoint_info.get("has_blade", false)
		player.has_wand = checkpoint_info.get("has_wand", false)
		
		if checkpoint_info.has("inventory_data") and inventory_system:
			inventory_system.load_data(checkpoint_info["inventory_data"])
		
		if player.has_blade:
			player.collected_blade()
		
		# logger.info("✅ Respawned at '%s'" % [current_checkpoint_id])

func has_checkpoint() -> bool:
	return not current_checkpoint_id.is_empty()

# --- LOAD SYSTEM ---
func load_checkpoint_data() -> void:
	var save_data = SaveSystem.load_checkpoint_data()
	if save_data.is_empty(): return
	
	current_checkpoint_id = save_data.get("checkpoint_id", "")
	var player_data = save_data.get("player", {})
	var inventory_data = save_data.get("inventory_data", {})
	
	# Lấy data skill tree (Key này phải khớp với SaveSystem)
	var skill_tree_data = save_data.get("skill_tree", {}) 

	if inventory_data and inventory_system:
		inventory_system.load_data(inventory_data)
	
	# LOAD VÀO MANAGER
	SkillTreeManager.load_data(skill_tree_data)
	
	if not current_checkpoint_id.is_empty():
		checkpoint_data[current_checkpoint_id] = player_data
		
func clear_checkpoint_data() -> void:
	current_checkpoint_id = ""
	checkpoint_data.clear()
	SaveSystem.delete_save_file()

func collect_blade() -> void:
	if has_blade: return
	has_blade = true
	if player: player.collected_blade()

func collect_wand() -> void:
	if has_wand: return
	has_wand = true
	if player: player.collected_wand()
	
func scale_health() ->void:
	get_tree().call_group("enemies", "scale_health", 0.8 + 0.2 * current_level)
