extends BlackEmperorState

## Cutscene 4: Placeholder - Chưa implement
## Sẽ chạy animation cutscene4 trong 2 giây
## Sau khi xong sẽ trigger boss mất 1/3 máu và chuyển phase

var cutscene_duration: float = 2.0
var animated_bg: AnimatedSprite2D = null

func _enter() -> void:
	print("State: Cutscene4 Enter")
	obj.change_animation("inactive")
	obj.velocity = Vector2.ZERO
	timer = cutscene_duration
	
	# Tìm AnimatedBg
	if animated_bg == null:
		animated_bg = obj.get_tree().get_first_node_in_group("animated_bg")
	
	# Tự trigger animation cutscene4
	if animated_bg:
		animated_bg.play("cutscene4")
		print("Cutscene4: Playing animation cutscene4")

func _update(_delta: float) -> void:
	obj.velocity = Vector2.ZERO
	
	# Sau 2 giây, kết thúc tất cả cutscenes
	if update_timer(_delta):
		print("State: Cutscene4 finished - All cutscenes complete")
		# Emit signal để AnimatedBg biết đã xong
		if animated_bg:
			animated_bg.all_cutscenes_finished.emit()
		# AnimatedBg sẽ trigger take_damage và boss chuyển sang phase GROUND

func _exit() -> void:
	pass
