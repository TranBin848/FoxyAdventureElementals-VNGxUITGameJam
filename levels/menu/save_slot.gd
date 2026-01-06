extends HBoxContainer
class_name SaveSlot

signal slot_selected(slot_index: int)
signal slot_deleted(slot_index: int)

@onready var save_button: Button = $Save

var slot_index: int = -1

func setup(index: int, metadata: Dictionary) -> void:
	slot_index = index
	
	if metadata.is_empty():
		save_button.text = "Slot %d\n[ Empty - Create New ]" % index
		modulate = Color(0.7, 0.7, 0.7)
	else:
		var date = metadata.get("timestamp", "Unknown Date")
		var level = metadata.get("stage_path", "").get_file().replace(".tscn", "")
		save_button.text = "Slot %d\n%s\n%s" % [index, level.capitalize(), date]
		modulate = Color.WHITE

func _on_save_pressed() -> void:
	slot_selected.emit(slot_index)
	
func _on_delete_pressed() -> void:
	slot_deleted.emit(slot_index)
