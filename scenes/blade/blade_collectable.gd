extends RigidBody2D


func _on_body_entered(body: Node2D) -> void:
	if body.has_method("collect_blade"):
		if body.has_blade:
			return
		body.collect_blade()
		queue_free()
