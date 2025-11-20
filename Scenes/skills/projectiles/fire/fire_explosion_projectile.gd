extends ProjectileBase
class_name FireExplosionProjectile

# --- Explosion Config ---
@export var start_scale: Vector2 = Vector2.ONE
@export var end_scale: Vector2 = Vector2(2.0, 2.0)
@export var scale_duration: float = 0.18
@export var scale_trans := Tween.TRANS_SINE
@export var scale_ease := Tween.EASE_OUT
@export var explosion_anim: String = "FireExplosion_End"

# --- State ---
var exploding: bool = false


func _on_hit_area_2d_hitted(area: Variant) -> void:
	_trigger_explosion()


func _on_body_entered(body: Node2D) -> void:
	_trigger_explosion()


func _trigger_explosion() -> void:
	if exploding:
		return
	
	exploding = true
	set_physics_process(false)

	# Reset scale + play animation
	$AnimatedSprite2D.scale = start_scale
	$AnimatedSprite2D.play(explosion_anim)

	# Explosion scale tween
	var tween := create_tween()
	tween.tween_property(
		$AnimatedSprite2D,
		"scale",
		end_scale,
		scale_duration
	).set_trans(scale_trans).set_ease(scale_ease)

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


func _on_animation_finished() -> void:
	queue_free()
