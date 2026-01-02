class_name KingCrabState
extends EnemyState

func control_moving() -> bool:
	obj.velocity.x = obj.movement_speed * obj.direction
	if _should_turn_around():
		obj.turn_around()
	return false

func _should_turn_around() -> bool:
	if (obj.is_touch_wall() or obj.is_can_fall()) and obj.is_on_floor():
		return true
	if obj.is_at_camera_edge():
		return true
	return false

func take_damage(_direction: Variant, damage: int = 1) -> void:
	#Enemy take damage
	obj.take_damage(damage)
	#obj.velocity.x = bounce_back_velocity * direction.x
	if obj.health <= 0:
		change_state(fsm.states.dead)
