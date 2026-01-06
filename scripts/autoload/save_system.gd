extends Node

# Base path pattern. %d will be replaced by the slot number (1, 2, 3)
const SAVE_PATH_TEMPLATE: String = "user://save_slot_%d.dat"
const CURRENT_VERSION: String = "1.0.0"

# --- HELPER: Get Dynamic Path ---
func get_save_path(slot_index: int) -> String:
	return SAVE_PATH_TEMPLATE % slot_index

# --- CORE: Save ---
func save_game(slot_index: int, checkpoint_id: String, player_data: Dictionary, stage_path: String, skill_tree_data: Dictionary, guide_data: Dictionary) -> void:
	
	var meta_data := {
		"version": CURRENT_VERSION,
		"timestamp": Time.get_datetime_string_from_system(),
		"unix_time": Time.get_unix_time_from_system()
	}

	var save_data := {
		"meta": meta_data,
		"checkpoint_id": checkpoint_id,
		"stage_path": stage_path,
		"player": player_data,
		"skill_tree": skill_tree_data,
		"guide": guide_data
	}

	var file_path = get_save_path(slot_index)
	var file := FileAccess.open(file_path, FileAccess.WRITE)
	
	if file:
		file.store_line(JSON.stringify(save_data))
		file.close()
		print("💾 Saved to Slot %d" % slot_index)
	else:
		push_error("❌ Failed to write to slot %d" % slot_index)

# --- CORE: Load ---
func load_game(slot_index: int) -> Dictionary:
	var file_path = get_save_path(slot_index)
	
	if not FileAccess.file_exists(file_path):
		return {}

	var file := FileAccess.open(file_path, FileAccess.READ)
	if not file: return {}
	
	var json = JSON.new()
	var result = json.parse(file.get_as_text())
	
	if result == OK:
		return json.data
	return {}

# --- UTILS: For the UI ---
func delete_slot(slot_index: int) -> void:
	var path = get_save_path(slot_index)
	if FileAccess.file_exists(path):
		DirAccess.remove_absolute(path)

func get_slot_metadata(slot_index: int) -> Dictionary:
	"""
	Reads ONLY the save file to return info for the UI buttons 
	(e.g., 'Level 5 - 2024-01-01') without loading the whole game state.
	"""
	var data = load_game(slot_index)
	if data.is_empty():
		return {} # Slot is empty
	
	# Extract just what we need for the menu
	return {
		"exists": true,
		"timestamp": data.meta.timestamp,
		"stage_path": data.stage_path,
		"level": data.get("player", {}).get("level", 1) # Example usage
	}
