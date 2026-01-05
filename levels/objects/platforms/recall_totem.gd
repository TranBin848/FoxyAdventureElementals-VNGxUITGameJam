extends StaticBody2D

# Assign the Path2D platform in the Inspector
@export var target_platform: Path2D 
@onready var label = $RichTextLabel
var tween: Tween = null  # Add tween variable

func _on_interactive_area_2d_interacted() -> void:
	if target_platform and target_platform.has_method("recall"):
		target_platform.recall()
		
func _on_interactive_area_2d_interaction_available() -> void:
	show_text()
	
func _on_interactive_area_2d_interaction_unavailable() -> void:
	hide_text() # Replace with function body.

func show_text() -> void:
	if tween:
		tween.kill()
		
	label.visible = true
	tween = create_tween()
	tween.parallel().tween_property(label, "modulate:a", 1.0, 0.5).from(0.0)
	tween.parallel().tween_property(label, "position:y", -56.0, 0.5).from(-28.0)
	tween.tween_interval(2.0)
	tween.tween_callback(hide_text)


func hide_text() -> void:
	if tween:
		tween.kill()
	
	tween = create_tween()
	tween.parallel().tween_property(label, "modulate:a", 0.0, 0.5)
	tween.parallel().tween_property(label, "position:y", -88.0, 0.5)
