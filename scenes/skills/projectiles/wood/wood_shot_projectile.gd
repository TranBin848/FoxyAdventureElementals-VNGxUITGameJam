extends ProjectileBase
class_name woodShotProjectile

func _on_hit_area_2d_hitted(area: Variant) -> void:
	if $AnimatedSprite2D.animation != "WoodShot_End":
		$AnimatedSprite2D.play("WoodShot_End")
		set_physics_process(false)
		$AnimatedSprite2D.connect("animation_finished", Callable(self, "_on_animation_finished"), CONNECT_ONE_SHOT)

func _on_body_entered(body: Node2D) -> void:
	if $AnimatedSprite2D.animation != "WoodShot_End":
		$AnimatedSprite2D.play("WoodShot_End")
		set_physics_process(false)
		$AnimatedSprite2D.connect("animation_finished", Callable(self, "_on_animation_finished"), CONNECT_ONE_SHOT)
	

func _on_animation_finished() -> void:
	queue_free()
