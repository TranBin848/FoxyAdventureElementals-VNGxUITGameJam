extends BlackEmperorState

## Cutscene 2: Placeholder - Chưa implement
## Sẽ chạy animation cutscene2 trong 2 giây

var cutscene_duration: float = 2.0
var animated_bg: AnimatedSprite2D = null

func _enter() -> void:
	print("State: Cutscene2 Enter")
	obj.change_animation("inactive")
	obj.velocity = Vector2.ZERO
	timer = cutscene_duration
	
	# Tìm AnimatedBg
	if animated_bg == null:
		animated_bg = obj.get_tree().get_first_node_in_group("animated_bg")
	
	# Tự trigger animation cutscene2
	if animated_bg:
		animated_bg.play("cutscene2")
		print("Cutscene2: Playing animation cutscene2")

func _update(_delta: float) -> void:
	obj.velocity = Vector2.ZERO
	
	# Tự động chuyển sang cutscene3 sau 2 giây
	if update_timer(_delta):
		print("State: Cutscene2 -> Cutscene3 transition")
		fsm.change_state(fsm.states.cutscene3)

func _exit() -> void:
	pass
