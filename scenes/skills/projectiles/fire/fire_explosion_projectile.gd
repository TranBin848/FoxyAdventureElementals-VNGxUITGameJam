extends ProjectileBase
class_name StunBeam

# --- Explosion Config ---
@export var start_scale: Vector2 = Vector2.ONE
@export var end_scale: Vector2 = Vector2(2.0, 2.0)
@export var scale_duration: float = 0.18
@export var scale_trans := Tween.TRANS_SINE
@export var scale_ease := Tween.EASE_OUT
@export var explosion_anim: String = "FireExplosion_End"
@onready var explosion_area: Area2D = $ExplosionArea	
@export var knockback_force: float = 300.0
@export var vertical_offset: float = -20.0
@export var knockback_upward_bias: float = 0.3  # Add slight upward lift

# --- State ---
var exploding: bool = false
var explosion_center: Vector2  # Store explosion position


func _on_hit_area_2d_hitted(area: Variant) -> void:
	_trigger_explosion()


func _on_body_entered(body: Node2D) -> void:
	_trigger_explosion()


func _trigger_explosion() -> void:
	if exploding:
		return
	
	exploding = true
	explosion_center = global_position  # Store center position
	
	# Find all enemies in explosion radius
	var overlaps = explosion_area.get_overlapping_bodies()
	print(overlaps)
	for b in overlaps:
		if b is EnemyCharacter:
			affected_enemies.append(b)
			b.enter_tornado(explosion_center)  # Pull to center
	
	# Reset scale + play animation
	$AnimatedSprite2D.scale = start_scale
	$AnimatedSprite2D.play(explosion_anim)
	
	var initial_sprite_pos_y = $AnimatedSprite2D.position.y 
	
	# Explosion scale tween
	var tween := create_tween()
	tween.tween_property(
		$AnimatedSprite2D,
		"scale",
		end_scale,
		scale_duration
	).set_trans(scale_trans).set_ease(scale_ease)

	# Position Y tween
	tween.tween_property(
		$AnimatedSprite2D,
		"position:y",
		initial_sprite_pos_y + vertical_offset,
		scale_duration
	).set_trans(scale_trans).set_ease(scale_ease).set_delay(0.0)
	
	# Cleanup
	$AnimatedSprite2D.connect(
		"animation_finished",
		Callable(self, "_on_animation_finished"),
		CONNECT_ONE_SHOT
	)


func _physics_process(delta: float) -> void:
	if exploding:
		return
	
	super._physics_process(delta)
	rotation = 0


func _on_animation_finished() -> void:
	for e in affected_enemies:
		if e and is_instance_valid(e) and e.is_inside_tree():
			e.exit_skill()

			# Calculate radial knockback direction
			var direction = (e.global_position - explosion_center).normalized()
			
			# Create knockback vector with upward component
			var knockback_vector = Vector2(
				direction.x * knockback_force,
				direction.y * knockback_force - (knockback_force * knockback_upward_bias)
			)
			
			e.apply_knockback(knockback_vector)
	
	queue_free()
