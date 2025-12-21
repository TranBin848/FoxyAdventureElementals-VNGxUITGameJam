extends Node

## Save system for persistent checkpoint data
const SAVE_FILE: String = "user://checkpoint_save.dat"

# 🔹 ĐÃ SỬA: Gộp skill_stack và skill_bar thành một biến 'skill_tree_data'
func save_checkpoint_data(checkpoint_id: String, player_data: Dictionary, stage_path: String, skill_tree_data: Dictionary) -> void:
	var save_data := {
		"checkpoint_id": checkpoint_id,
		"player": player_data,          # Chứa cả inventory và state player
		"stage_path": stage_path,
		"skill_tree": skill_tree_data   # <--- Thay đổi ở đây: Lưu toàn bộ data của SkillTreeManager
	}

	var file := FileAccess.open(SAVE_FILE, FileAccess.WRITE)
	if file == null:
		push_error("❌ Không mở được file save để ghi.")
		return

	file.store_line(JSON.stringify(save_data))
	file.close()
	# print("✅ Đã lưu checkpoint:", checkpoint_id, "ở stage:", stage_path)


# 🔹 Load checkpoint data từ file (Giữ nguyên logic, chỉ cần return Dictionary chuẩn)
func load_checkpoint_data() -> Dictionary:
	if not has_save_file():
		# print(ProjectSettings.globalize_path(SAVE_FILE))
		# print("⚠️ Không tìm thấy file save, bắt đầu mới.")
		return {}

	var file := FileAccess.open(SAVE_FILE, FileAccess.READ)
	if file == null:
		push_error("❌ Không thể mở file save để đọc.")
		return {}

	var result: Variant = JSON.parse_string(file.get_as_text())
	file.close()

	if typeof(result) == TYPE_DICTIONARY:
		# print("✅ Đã load dữ liệu checkpoint.")
		return result
	else:
		push_error("❌ Dữ liệu checkpoint không hợp lệ.")
		return {}


# 🔹 Kiểm tra tồn tại file save
func has_save_file() -> bool:
	return FileAccess.file_exists(SAVE_FILE)


# 🔹 Xóa file save
func delete_save_file() -> void:
	if has_save_file():
		var err := DirAccess.remove_absolute(SAVE_FILE)
		if err == OK:
			print("🗑️ Đã xóa file save.")
		else:
			push_error("❌ Xóa file save thất bại: %s" % str(err))
