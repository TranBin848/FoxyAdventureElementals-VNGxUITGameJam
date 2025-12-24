extends ProjectileBase
class_name StunBeamProjectile

# --- Stun Config ---
@export var start_scale: Vector2 = Vector2.ONE
@export var end_scale: Vector2 = Vector2(2.0, 2.0)
@export var scale_duration: float = 0.18
@export var scale_trans := Tween.TRANS_SINE
@export var scale_ease := Tween.EASE_OUT
@export var stun_anim: String = "StunBeam"
@onready var stun_area: Area2D = $StunArea	
@export var knockback_force: float = 300.0
@export var vertical_offset: float = -20.0
@export var knockback_upward_bias: float = 0.3

# --- State ---
var exploding: bool = false
var stun_center: Vector2

func _ready() -> void:
	_trigger_stun()
	
	if has_node("AnimatedSprite2D"):
		get_node("AnimatedSprite2D").animation_finished.connect(_on_animation_finished, CONNECT_ONE_SHOT)

func _trigger_stun() -> void:
	if exploding:
		return
	
	exploding = true
	stun_center = global_position
	set_physics_process(false)
	
	# --- FIX START ---
	# Wait for the physics server to update this new Area2D's collisions
	await get_tree().physics_frame
	await get_tree().physics_frame 
	# (Sometimes 2 frames are safer to ensure position updates propagate)
	# --- FIX END ---
	
	# Find any additional enemies in stun area (in case they walked into range)
	if stun_area:
		var overlaps = stun_area.get_overlapping_bodies()
		for b in overlaps:
			if b is EnemyCharacter and not affected_enemies.has(b):
				affected_enemies.append(b)
				b.enter_stun(stun_center)
	
	# Reset scale + play animation
	if has_node("AnimatedSprite2D"):
		var sprite = get_node("AnimatedSprite2D")
		sprite.scale = start_scale
		sprite.play(stun_anim)
		
		var initial_sprite_pos_y = sprite.position.y 
		
		# Stun scale tween
		var tween := create_tween()
		tween.tween_property(
			sprite,
			"scale",
			end_scale,
			scale_duration
		).set_trans(scale_trans).set_ease(scale_ease)

		# Position Y tween
		tween.tween_property(
			sprite,
			"position:y",
			initial_sprite_pos_y + vertical_offset,
			scale_duration
		).set_trans(scale_trans).set_ease(scale_ease).set_delay(0.0)

func _physics_process(delta: float) -> void:
	if exploding:
		return
	
	super._physics_process(delta)
	rotation = 0

func _on_animation_finished() -> void:
	print("=== Animation Finished ===")
	print("Total affected enemies: ", affected_enemies.size())
	print("Affected enemies: ", affected_enemies)
	
	var processed_count = 0
	for e in affected_enemies:
		print("Checking enemy ", processed_count, ": ", e)
		
		if not e:
			print("  -> Enemy is null")
			continue
		
		if not is_instance_valid(e):
			print("  -> Enemy is not valid")
			continue
		
		if not e.is_inside_tree():
			print("  -> Enemy is not in tree")
			continue
		
		print("  -> Processing enemy: ", e.name, " at ", e.global_position)
		
		# Exit skill to restore movement
		e.exit_skill()
		processed_count += 1
		print("  -> Called exit_skill (", processed_count, " total)")
		
		# Calculate radial knockback direction
		var _direction = (e.global_position - stun_center).normalized()
		
		var knockback_vector = Vector2(
			_direction.x * knockback_force,
			(_direction.y * knockback_force) - (knockback_force * knockback_upward_bias)
		)
		
		e.apply_knockback(knockback_vector)
		
		print("  -> Applied knockback")
	
	print("Total processed: ", processed_count, " / ", affected_enemies.size())
	queue_free()
