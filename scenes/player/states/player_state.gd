class_name PlayerState
extends FSMState

const DEFAULT_KNOCKBACK_FORCE := 100.0
const ACCELERATION = 1500.0
const FRICTION = 800.0
const AIR_FRICTION_MULTIPLIER = 0.25  # Much less friction in air

func control_moving() -> bool:
	var delta = obj.get_physics_process_delta_time()
	
	# SOCD Handling
	if Input.is_action_just_pressed("right"):
		obj.last_dir = 1
	if Input.is_action_just_pressed("left"):
		obj.last_dir = -1
	
	# Determine actual direction
	var right_held = Input.is_action_pressed("right")
	var left_held = Input.is_action_pressed("left")
	var dir: int = 0
	
	if right_held and left_held:
		dir = obj.last_dir
	elif right_held:
		dir = 1
		obj.last_dir = 1
	elif left_held:
		dir = -1
		obj.last_dir = -1
	else:
		obj.last_dir = 0
	
	var target_speed = obj.movement_speed * dir * obj.speed_multiplier
	
	# === COYOTE TIME + AIR CONTROL ===
	var has_ground_control = obj.has_coyote_time()  # True if grounded OR within coyote time
	
	if dir != 0:
		if has_ground_control:
			# Ground Control: Smooth acceleration
			obj.velocity.x = move_toward(obj.velocity.x, target_speed, ACCELERATION * delta)
		else:
			# Air Control: Faster/more responsive
			var air_accel = ACCELERATION * obj.air_control_multiplier
			obj.velocity.x = move_toward(obj.velocity.x, target_speed, air_accel * delta)
		
		obj.change_direction(dir)
		
		# Only change to run state when actually grounded
		if obj.is_on_floor() and fsm.current_state != fsm.states.run:
			change_state(fsm.states.run)
		return true
		
	else:
		# No input - apply friction
		if fsm.current_state.name == "Dash":
			return false
		
		if has_ground_control:
			# Ground: Normal friction
			obj.velocity.x = move_toward(obj.velocity.x, 0, FRICTION * delta)
		else:
			# Air: Reduced friction (preserve momentum)
			obj.velocity.x = move_toward(obj.velocity.x, 0, FRICTION * AIR_FRICTION_MULTIPLIER * delta)
		return false

func control_jump() -> bool:
	# Check if jump was buffered OR just pressed
	var wants_jump = obj.jump_buffer_timer > 0
	
	if wants_jump and obj.has_coyote_time():
		obj.jump()
		obj.coyote_timer = 0       # Correct: Clear coyote time
		obj.jump_buffer_timer = 0  # Correct: Consume buffer
		change_state(fsm.states.jump)
		return true
	return false

func control_wall_jump() -> bool:
	if Input.is_action_just_pressed("jump"):
		obj.wall_jump()
		change_state(fsm.states.walljump)
		return true
	return false

func control_dash() -> bool:
	if Input.is_action_just_pressed("dash") and obj.can_dash:
		change_state(fsm.states.dash)
		return true
	return false

# endregion

# region Combat Controls
# ------------------------------------------------------------------------------

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

func control_swap_weapon() -> bool:
	if Input.is_action_just_pressed("swap_weapon"):
		# Player.gd handles the validation logic internally
		obj.swap_weapon()
		return true
	return false

# endregion

# region Damage & State Logic
# ------------------------------------------------------------------------------

func take_damage(knockback_dir: Vector2, damage: int = 1) -> void:
	# FIX: Access the variable directly instead of calling the old function
	if obj.is_invulnerable:
		return
		
	# Apply Damage
	obj.take_damage(damage)
	
	# Apply Knockback
	# Ensure knockback_dir is normalized (-1 or 1 on X)
	var k_dir = sign(knockback_dir.x) if knockback_dir.x != 0 else -obj.direction
	obj.velocity.x = DEFAULT_KNOCKBACK_FORCE * k_dir
	
	# Transition
	if obj.health <= 0:
		change_state(fsm.states.dead)
	else:
		change_state(fsm.states.hurt)

# endregion
