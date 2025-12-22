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
		push_error("❌ Không thể mở file save để đọc.")
		return {}

	var result: Variant = JSON.parse_string(file.get_as_text())
	file.close()

	if typeof(result) == TYPE_DICTIONARY:
		return result
	else:
		push_error("❌ Dữ liệu checkpoint không hợp lệ.")
		return {}

func has_save_file() -> bool:
	return FileAccess.file_exists(SAVE_FILE)

func delete_save_file() -> void:
	if has_save_file():
		var err := DirAccess.remove_absolute(ProjectSettings.globalize_path(SAVE_FILE))
		if err != OK:
			push_error("❌ Xóa file save thất bại: %s" % str(err))
