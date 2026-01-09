extends BlackEmperorState

var cutscene_duration: float = 8.0  # Tổng thời gian cutscene (cutscene1 + 2s + 2s + 2s)

func _enter() -> void:
	print("State: Cutscene Enter")
	obj.change_animation("inactive")
	obj.velocity = Vector2.ZERO
	timer = cutscene_duration

func _update(_delta: float) -> void:
	# Đứng im trong lúc cutscene
	obj.velocity = Vector2.ZERO
	
	# Sau khi cutscene xong, AnimatedBg sẽ tự trigger take_damage
	# Và boss sẽ tự động chuyển sang phase GROUND
	if update_timer(_delta):
		print("State: Cutscene finished, waiting for phase transition")
