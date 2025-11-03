extends RigidBody2D

func _on_body_entered(body: Node) -> void:
	queue_free()
	pass


func _on_hit_area_2d_hitted(area: Variant) -> void:
	queue_free()
	pass
