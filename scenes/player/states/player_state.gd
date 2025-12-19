class_name PlayerState
extends FSMState



#Control moving and changing state to run
#Return true if moving
func control_moving() -> bool:
	var dir: float = Input.get_action_strength("right") - Input.get_action_strength("left")
	
	if (Input.is_action_just_pressed("right")):
		obj.last_dir = Input.get_action_strength("right")
	if (Input.is_action_just_pressed("left")):
		obj.last_dir = -Input.get_action_strength("left")
	if (Input.get_action_strength("right") + Input.get_action_strength("left") == 0):
		obj.last_dir = 0
	if (Input.get_action_strength("right") + Input.get_action_strength("left") > 1):
		dir = obj.last_dir
		
	var is_moving: bool = abs(dir) > 0.1
	if is_moving:
		dir = sign(dir)
		obj.change_direction(dir)
		obj.velocity.x = obj.movement_speed * dir * obj.speed_multiplier
		if obj.is_on_floor():
			change_state(fsm.states.run)
		return true
	else:
		obj.velocity.x = 0
		#print(fsm.current_state.name)
		if fsm.current_state.name == "Dash":
			#print("Dash")
			pass
	return false

#Control jumping
#Return true if jumping
func control_jump() -> bool:
	#If jump is pressed change to jump state and return true
	if Input.is_action_just_pressed("jump"):
		obj.jump()
		change_state(fsm.states.jump)
		return true
	return false

func control_wall_jump() -> bool:
	#If jump is pressed change to jump state and return true
	if Input.is_action_just_pressed("jump"):
		obj.wall_jump()
		change_state(fsm.states.walljump)
		return true
	return false

func control_attack() -> bool:
	if Input.is_action_just_pressed("attack") and obj.can_attack():
		change_state(fsm.states.attack)
		return true
	return false
	
func control_jump_attack() -> bool:
	if Input.is_action_just_pressed("attack") and obj.can_attack():
		change_state(fsm.states.jumpattack)
		return true
	return false

func control_throw_blade() -> bool:
	if Input.is_action_just_pressed("throw") and obj.can_throw():
		change_state(fsm.states.throwattack)
		return true
	return false

func control_dash() -> void:
	if Input.is_action_just_pressed("dash") and obj.can_dash:
		change_state(fsm.states.dash)
		
func control_swap_weapon() -> bool:
	if Input.is_action_just_pressed("swap_weapon"): 
		
		# Player.swap_weapon() đã tự xử lý việc kiểm tra xem có vũ khí để đổi hay không.
		obj.swap_weapon()
		
		# Không cần đổi trạng thái FSM (vì swap weapon là một hành động tức thời, không chặn)
		return true
	return false		

func take_damage(direction: Variant, damage: int = 1) -> void:
	if obj.is_char_invulnerable():
		return
	#Player take damage
	obj.take_damage(damage)

	obj.velocity.x = 250 * direction.x
	#Player die if health is 0 and change to dead state
	#Player hurt if health is not 0 and change to hurt state
	if obj.health <= 0:
		change_state(fsm.states.dead)
	else:
		change_state(fsm.states.hurt)
