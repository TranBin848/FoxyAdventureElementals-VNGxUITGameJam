extends BlackEmperorState

## Cutscene 3: Placeholder - Chưa implement
## Sẽ chạy animation cutscene3 trong 2 giây

var cutscene_duration: float = 2.0
var animated_bg: AnimatedSprite2D = null

func _enter() -> void:
	print("State: Cutscene3 Enter")
	obj.change_animation("inactive")
	obj.velocity = Vector2.ZERO
	timer = cutscene_duration
	
	# Tìm AnimatedBg
	if animated_bg == null:
		animated_bg = obj.get_tree().get_first_node_in_group("animated_bg")
	
	# Tự trigger animation cutscene3
	if animated_bg:
		animated_bg.play("cutscene3")
		print("Cutscene3: Playing animation cutscene3")

func _update(_delta: float) -> void:
	obj.velocity = Vector2.ZERO
	
	# Tự động chuyển sang cutscene4 sau 2 giây
	if update_timer(_delta):
		print("State: Cutscene3 -> Cutscene4 transition")
		fsm.change_state(fsm.states.cutscene4)


func _exit() -> void:
	pass
