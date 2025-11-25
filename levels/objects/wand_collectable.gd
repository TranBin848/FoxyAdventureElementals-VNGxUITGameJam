extends RigidBody2D


func _on_collectable_area_2d_body_entered(body: Node2D) -> void:
	if body is Player:
		var player = body as Player
		
		# Kiểm tra xem Player đã có Wand chưa (hoặc có Blade không)
		# Nếu đã có, bạn có thể chọn không nhặt hoặc thay thế.
		
		# Nếu Player có hàm collected_wand và chưa có vũ khí mới:
		if player.has_method("collected_wand") and not player.has_wand:
			player.collected_wand()
			queue_free()
