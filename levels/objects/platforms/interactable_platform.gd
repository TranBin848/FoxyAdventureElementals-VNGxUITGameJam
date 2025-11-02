extends Path2D

@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var path_follow_2d: PathFollow2D = $PathFollow2D


func _on_interactive_area_2d_interacted() -> void:
	if animation_player.current_animation == "move":
		animation_player.speed_scale *= -1
		return
	
	animation_player.speed_scale = 1
	if path_follow_2d.progress_ratio == 0:
		animation_player.play("move")
	elif path_follow_2d.progress_ratio == 1:
		animation_player.play_backwards("move")
