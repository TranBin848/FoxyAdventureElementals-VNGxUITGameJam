extends PlayerState

func _enter() -> void:
	$"../../Direction/HurtArea2D/CollisionShape2D".disabled = true
	obj.set_collision_mask_value(9, false)
	obj.velocity.x = 0
	
func _update(delta: float) -> void:
	if obj.is_actor_moving:
		obj._handle_actor_physics()
	#pass
	
#func _input(event: InputEvent) -> void:
	#if event is InputEventKey:
		#if event.pressed and not event.echo:
			#change_state(fsm.states.idle)

func _exit() -> void:
	$"../../Direction/HurtArea2D/CollisionShape2D".disabled = false
	obj.set_collision_mask_value(9, true)
