extends ProjectileBase
class_name waterBlastProjectile

func _ready() -> void:
	if has_node("HitArea2D"):
		var hit_area: HitArea2D = $HitArea2D
		hit_area.damage = damage
		hit_area.elemental_type = elemental_type

func _on_hit_area_2d_hitted(_area: Variant) -> void:
	if $AnimatedSprite2D.animation != "WaterBlast_End":
		$AnimatedSprite2D.play("WaterBlast_End")
		set_physics_process(false)
		$AnimatedSprite2D.connect("animation_finished", Callable(self, "_on_animation_finished"), CONNECT_ONE_SHOT)


func _on_body_entered(_body: Node2D) -> void:
	if $AnimatedSprite2D.animation != "WaterBlast_End":
		$AnimatedSprite2D.play("WaterBlast_End")
		set_physics_process(false)
		$AnimatedSprite2D.connect("animation_finished", Callable(self, "_on_animation_finished"), CONNECT_ONE_SHOT)

func _on_animation_finished() -> void:
	queue_free()
