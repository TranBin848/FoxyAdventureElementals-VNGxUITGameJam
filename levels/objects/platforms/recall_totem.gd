extends StaticBody2D

# Assign the Path2D platform in the Inspector
@export var target_platform: Path2D 

func _on_interactive_area_2d_interacted() -> void:
	if target_platform and target_platform.has_method("recall"):
		target_platform.recall()
