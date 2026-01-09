extends ProjectileBase
class_name fireShotProjectileBoss

func _on_hit_area_2d_hitted(_area: Variant) -> void:
	if $AnimatedSprite2D.animation != "FireShot_End":
		$AnimatedSprite2D.play("FireShot_End")
		set_physics_process(false)
		$AnimatedSprite2D.connect("animation_finished", Callable(self, "_on_animation_finished"), CONNECT_ONE_SHOT)

func _on_body_entered(_body: Node2D) -> void:
	if $AnimatedSprite2D.animation != "FireShot_End":
		$AnimatedSprite2D.play("FireShot_End")
		set_physics_process(false)
		$AnimatedSprite2D.connect("animation_finished", Callable(self, "_on_animation_finished"), CONNECT_ONE_SHOT)
	

func _on_animation_finished() -> void:
	queue_free()
