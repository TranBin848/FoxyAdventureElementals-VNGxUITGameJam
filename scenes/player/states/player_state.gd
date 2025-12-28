class_name PlayerState
extends FSMState

# Constant for knockback if not defined in Player
const DEFAULT_KNOCKBACK_FORCE := 250.0
const ACCELERATION = 800.0
const FRICTION = 1000.0

# region Movement Controls
# ------------------------------------------------------------------------------

func control_moving() -> bool:
	var dir: float = Input.get_axis("left", "right")
	
	# Calculate target speed (Where we WANT to be)
	var target_speed = obj.movement_speed * dir * obj.speed_multiplier
	
	if dir != 0:
		# Accel: Smoothly move current velocity toward target speed
		# get_physics_process_delta_time() is safer than passing delta manually
		var delta = obj.get_physics_process_delta_time()
		obj.velocity.x = move_toward(obj.velocity.x, target_speed, ACCELERATION * delta)
		
		# Facing direction logic (only flip if actually moving input)
		obj.change_direction(dir)
		
		if obj.is_on_floor() and fsm.current_state != fsm.states.run:
			change_state(fsm.states.run)
		return true
		
	else:
		# Friction: Smoothly reduce speed to 0
		var delta = obj.get_physics_process_delta_time()
		obj.velocity.x = move_toward(obj.velocity.x, 0, FRICTION * delta)
		return false

func control_jump() -> bool:
	if Input.is_action_just_pressed("jump"):
		obj.jump()
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
