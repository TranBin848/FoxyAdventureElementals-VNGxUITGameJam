extends PlayerState

var start_x: float
var ghost_timer := 0.0
var ghost_cooldown := 0.02

@onready var ghost_fx_factory: Node2DFactory = $"../../Direction/GhostFXFactory"


func _enter() -> void:
	start_x = obj.global_position.x
	ghost_timer = 0.0
	
	# Set dash animation
	obj.change_animation("jump")
	AudioManager.play_sound("player_dash")
	
	obj.dash()

func _update(delta: float) -> void:
	# Spawn ghosts over time
	ghost_timer -= delta
	if ghost_timer <= 0.0:
		_spawn_ghost()
		ghost_timer = ghost_cooldown

	# Stop dash when reaching limit or hitting wall
	var dist: float = abs(obj.global_position.x - start_x)
	if dist >= obj.dash_dist or obj.is_on_wall():
		obj.velocity.x = 0
		obj.is_dashing = false
		

	# Transition when dash ends
	if not obj.is_dashing:
		if obj.is_on_floor():
			change_state(fsm.states.idle)
		else:
			change_state(fsm.states.jump)

func _exit() -> void:
	obj.is_dashing = false

func _spawn_ghost() -> void:
	var ghost := ghost_fx_factory.create() as Sprite2D
	var anim := obj.animated_sprite.animation
	var frame := obj.animated_sprite.frame

	# Copy texture from current animation frame
	ghost.texture = obj.animated_sprite.sprite_frames.get_frame_texture(anim, frame)

	# Copy visuals
	ghost.flip_h = (obj.direction < 0)
	ghost.scale = obj.animated_sprite.scale
	ghost.modulate = obj.animated_sprite.modulate
	ghost.rotation = obj.animated_sprite.rotation
	ghost.offset = obj.animated_sprite.offset

func  take_damage(direction: Variant, damage: int = 1) -> void:
	pass
