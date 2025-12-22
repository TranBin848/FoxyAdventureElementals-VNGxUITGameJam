extends KingCrabState

func _enter() -> void:
	obj.change_animation("inactive")
	obj.velocity.x = 0
	timer = 0
	$"../../Direction/HitArea2D/CollisionShape2D".disabled = true
	$"../../Direction/HurtArea2D/CollisionShape2D2".disabled = true

func _update(_delta: float) -> void:
	#dont do anything until player is found
	if obj.found_player == null:
		return
		
	fsm.change_state(fsm.states.standup)

func _exit() -> void:
	$"../../Direction/HitArea2D/CollisionShape2D".disabled = false
	$"../../Direction/HurtArea2D/CollisionShape2D2".disabled = false
