class_name EnemyState
extends FSMState

@export var bounce_back_velocity: float = 150

#Control moving and changing state to run
#Return true if moving
func control_moving() -> bool:
	if obj.is_on_floor():
		obj.velocity.x = obj.movement_speed * obj.direction
	if _should_turn_around():
		obj.turn_around()
	return false

func _should_turn_around() -> bool:
	return (obj.is_touch_wall() or obj.is_can_fall()) and obj.is_on_floor()

func take_damage(direction: Variant, damage: int = 1) -> void:
	#Enemy take damage
	obj.take_damage(damage)
	obj.velocity.x = bounce_back_velocity * direction.x
	#Enemy die if health is 0 and change to dead state
	#Enemy hurt if health is not 0 and change to hurt state
	if obj.health <= 0:
		change_state(fsm.states.dead)
	else:
		change_state(fsm.states.hurt)
