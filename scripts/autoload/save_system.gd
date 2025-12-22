extends Node

const SAVE_FILE: String = "user://checkpoint_save.dat"

func save_checkpoint_data(checkpoint_id: String, player_data: Dictionary, stage_path: String, skill_tree_data: Dictionary) -> void:
	var save_data := {
		"checkpoint_id": checkpoint_id,
		"player": player_data,
		"stage_path": stage_path,
		"skill_tree": skill_tree_data
	}

	var file := FileAccess.open(SAVE_FILE, FileAccess.WRITE)
	if file == null:
		push_error("❌ Không mở được file save để ghi.")
		return

	file.store_line(JSON.stringify(save_data))
	file.close()

func load_checkpoint_data() -> Dictionary:
	if not has_save_file():
		return {}

	var file := FileAccess.open(SAVE_FILE, FileAccess.READ)
	if file == null:
		return {}

	var json_text := file.get_as_text().strip_edges()  # Remove whitespace
	file.close()
	
	var json = JSON.new()
	var parse_result = json.parse(json_text)
	
	if parse_result != OK:
		push_error("❌ JSON Error %d: %s at line %d\n%s" % [
			parse_result, 
			json.get_error_message(), 
			json.get_error_line(), 
			json_text.substr(0, 100) + "..."
		])
		return {}

	var result: Dictionary = json.data
	# Validate required keys
	if not result.has("checkpoint_id") or not result.has("player"):
		push_error("❌ Missing required keys in save data")
		return {}
	
	return result

func has_save_file() -> bool:
	return FileAccess.file_exists(SAVE_FILE)

func delete_save_file() -> void:
	if has_save_file():
		var err := DirAccess.remove_absolute(ProjectSettings.globalize_path(SAVE_FILE))
		if err != OK:
			push_error("❌ Xóa file save thất bại: %s" % str(err))
