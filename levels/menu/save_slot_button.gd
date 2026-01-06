extends Button

signal slot_selected(slot_index: int)

var slot_index: int = -1

func setup(index: int, metadata: Dictionary) -> void:
	slot_index = index
	
	if metadata.is_empty():
		text = "Slot %d\n[ Empty - Create New ]" % index
		modulate = Color(0.7, 0.7, 0.7)
	else:
		var date = metadata.get("timestamp", "Unknown Date")
		var level = metadata.get("stage_path", "").get_file().replace(".tscn", "")
		text = "Slot %d\n%s\n%s" % [index, level.capitalize(), date]
		modulate = Color.WHITE

func _pressed() -> void:
	slot_selected.emit(slot_index)
