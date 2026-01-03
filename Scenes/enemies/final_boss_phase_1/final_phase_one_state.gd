class_name FinalPhaseOneState
extends EnemyState

#func control_moving() -> bool:
	#obj.velocity.x = obj.movement_speed * obj.direction
	#if _should_turn_around():
		#obj.turn_around()
	#return false
#
#func _should_turn_around() -> bool:
	#if (obj.is_touch_wall() or obj.is_can_fall()) and obj.is_on_floor():
		#return true
	#if obj.is_at_camera_edge():
		#return true
	#return false

func huhuhu() -> void:
	print()

func control_fly() -> void:
	obj.velocity.y = -1 * obj.movement_speed;

func take_damage(_direction: Variant, damage: int = 1) -> void:
	#Enemy take damage
	obj.take_damage(damage)
	#obj.velocity.x = bounce_back_velocity * direction.x
	if obj.health <= 0:
		change_state(fsm.states.dead)

func handle_mini_bosses() -> void:
	if obj.king_crab_instance.health <= 0:
		obj.hide_coroutine_king_crab()
	if obj.war_lord_instance.health <= 0:
		obj.hide_coroutine_war_lord()

var current_skill = 0
var total_skill = 2

func handle_attack() -> void:
	#obj.is_attacking = true
	#current_skill = (current_skill +1 ) % total_skill
	#if(current_skill == 0):
		#change_state(fsm.states.shootleft)
	#else:
		#change_state(fsm.states.launchrocket)
	pass

#extend if i have more time T.T

func reposition() -> void:
	pass
