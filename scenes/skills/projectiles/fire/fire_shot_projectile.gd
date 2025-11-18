extends ProjectileBase
class_name fireShotProjectile

func _on_hit_area_2d_hitted(area: Variant) -> void:
	if $AnimatedSprite2D.animation != "FireShot_Explosion":
		$AnimatedSprite2D.play("FireShot_Explosion")
		set_physics_process(false)
		$AnimatedSprite2D.connect("animation_finished", Callable(self, "_on_animation_finished"), CONNECT_ONE_SHOT)

func _on_body_entered(body: Node2D) -> void:
	if $AnimatedSprite2D.animation != "FireShot_Explosion":
		$AnimatedSprite2D.play("FireShot_Explosion")
		set_physics_process(false)
		$AnimatedSprite2D.connect("animation_finished", Callable(self, "_on_animation_finished"), CONNECT_ONE_SHOT)
	

func _on_animation_finished() -> void:
	queue_free()
