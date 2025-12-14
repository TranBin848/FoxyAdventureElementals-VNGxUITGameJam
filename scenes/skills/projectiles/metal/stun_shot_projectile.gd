extends ProjectileBase
class_name StunShotProjectile

@export var beam_scene: PackedScene = preload("res://scenes/skills/projectiles/metal/stun_beam.tscn")
@export var beam_spawn_delay_sec: float = 1.0

func _ready() -> void:
	$AnimatedSprite2D.play("StunShot_Start")
	
	$AnimatedSprite2D.animation_finished.connect(_on_sprite_animation_finished)

func _on_sprite_animation_finished() -> void:
	if $AnimatedSprite2D.animation == "StunShot_Start":
		$AnimatedSprite2D.play("StunShot_Flying")
	# When End finishes, we wait for the delayed beam coroutine to free

func _on_hit_area_2d_hitted(area: Variant) -> void:
	_trigger_death_and_spawn_beam()

func _on_body_entered(body: Node2D) -> void:
	_trigger_death_and_spawn_beam()

func _trigger_death_and_spawn_beam() -> void:
	if $AnimatedSprite2D.animation != "StunShot_End":
		set_physics_process(false)
		$AnimatedSprite2D.play("StunShot_End")
		# Start delayed beam spawn
		_spawn_beam_after_delay()


func _spawn_beam_after_delay() -> void:
	var hit_pos := global_position
	await get_tree().create_timer(beam_spawn_delay_sec).timeout
	if not is_inside_tree():
		return
	if beam_scene:
		var beam: Area2D = beam_scene.instantiate()
		beam.global_position = hit_pos
		# Pass damage and element to beam
		if beam is ProjectileBase:
			beam.damage = damage
			beam.elemental_type = elemental_type
		get_parent().add_child(beam)
	# Now free this projectile
	queue_free()
