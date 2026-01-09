extends Path2D

@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var path_follow_2d: PathFollow2D = $PathFollow2D
@onready var label = $PathFollow2D/AnimatableBody2D/RichTextLabel
var tween: Tween

func _on_interactive_area_2d_interacted() -> void:
	if animation_player.current_animation == "move":
		animation_player.speed_scale *= -1
		return
	
	animation_player.speed_scale = 1
	if path_follow_2d.progress_ratio == 0:
		animation_player.play("move")
	elif path_follow_2d.progress_ratio == 1:
		animation_player.play_backwards("move")

func recall() -> void:
	# If already at the start, do nothing
	if path_follow_2d.progress_ratio <= 0.01:
		return

	# If currently moving AWAY (speed_scale 1), reverse it
	if animation_player.is_playing():
		if animation_player.speed_scale > 0:
			animation_player.speed_scale = -1
		# If speed_scale is already -1 (coming back), do nothing
	else:
		# If stopped (likely at the end), play backwards
		animation_player.speed_scale = 1 # Reset scale to standard
		animation_player.play_backwards("move")

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


func _on_interactive_area_2d_interaction_available() -> void:
	show_text()
	
func _on_interactive_area_2d_interaction_unavailable() -> void:
	hide_text
