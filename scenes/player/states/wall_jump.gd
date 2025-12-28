extends PlayerState

# How long to ignore horizontal input (The "Kick" phase)
var lock_input_duration: float = 0.2 

func _enter() -> void:
	obj.change_animation("jump")
	AudioManager.play_sound("player_jump")
	
	# Reuse your parent class timer variable
	timer = lock_input_duration
	
	# CRITICAL: We do NOT set velocity here. 
	# We rely on Player.wall_jump() to have applied the force 
	# using _next_direction correctly.

func _update(_delta: float):
	# 1. Check Input Locking
	# We use the timer to deciding IF we allow movement.
	# We do NOT use it to change state.
	if timer > 0:
		timer -= _delta
		# Do nothing! Let the "Kick" velocity carry the player.
	else:
		# Timer is done. Allow Air Drift / Air Control.
		control_moving()
	
	# 2. Abilities
	control_dash()
	
	# 3. Transitions
	# Only switch to Fall if gravity has actually pulled us down
	if obj.velocity.y > 0:
		change_state(fsm.states.fall)
