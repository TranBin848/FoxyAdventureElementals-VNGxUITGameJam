extends Area2D

@export var launch_force: float = 600.0
@export var boost_modifier: float = 1.2 # Multiplier if holding jump
@export var only_launch_when_falling: bool = true

@onready var sprite: Sprite2D = $Sprite2D
# @onready var audio: AudioStreamPlayer2D = $AudioStreamPlayer2D

func _ready() -> void:
	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node2D) -> void:
	# 1. Validate Target
	if not body is Player: 
		return
	
	# 2. Check Direction (Optional but recommended)
	# Prevents triggering when jumping UP through the trampoline from below
	if only_launch_when_falling and body.velocity.y < 0:
		return

	# 3. Calculate Force (Check for Jump Boost)
	var final_force = launch_force
	if Input.is_action_pressed("jump"):
		final_force *= boost_modifier
		# print("BOOST JUMP!")
		
	# 4. Apply Physics
	_launch_player(body, final_force)
	
	AudioManager.play_sound("trampoline_bounce")
	
	# 5. Visual Feedback
	_play_squash_animation()
	# if audio.stream: audio.play()

func _launch_player(player: Player, force: float) -> void:
	# Reset vertical velocity to 0 first to ensure consistent height
	player.velocity.y = 0 
	player.velocity.y = -force
	
	# CRITICAL: Force Player FSM into Jump/Air state
	# If you don't do this, the "Run" or "Idle" state might snap the player back to floor
	player.fsm.change_state(player.fsm.states.jump)
		
	# Reset jump count if you have double jumps
	# player.jump_count = 0 

func _play_squash_animation() -> void:
	var tween = create_tween()
	# Squash down (Scale X up, Scale Y down)
	tween.tween_property(sprite, "scale", Vector2(1.4, 0.6), 0.05).set_trans(Tween.TRANS_QUAD)
	# Stretch up (Scale X down, Scale Y up)
	tween.tween_property(sprite, "scale", Vector2(0.8, 1.2), 0.1)
	# Return to normal
	tween.tween_property(sprite, "scale", Vector2(1.0, 1.0), 0.1)
