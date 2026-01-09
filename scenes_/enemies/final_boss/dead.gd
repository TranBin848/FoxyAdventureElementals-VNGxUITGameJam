extends BlackEmperorState

func _enter() -> void:
	print("=== State: Dead Enter ===")
	
	# Dừng mọi chuyển động
	obj.velocity = Vector2.ZERO
	obj.is_movable = false
	obj.is_stunned = true
	obj.set_physics_process(false)
	
	# Tắt collision để không tương tác nữa
	if obj.has_node("CollisionShape2D"):
		var collision = obj.get_node("CollisionShape2D")
		collision.set_deferred("disabled", true)
	
	# Play animation dead nếu có
	if obj.animated_sprite_2d and obj.animated_sprite_2d.sprite_frames.has_animation("dead"):
		obj.animated_sprite_2d.play("dead")
		await obj.animated_sprite_2d.animation_finished
		print("Dead: Animation finished")
	else:
		# Nếu không có animation dead, đợi 1 giây
		await get_tree().create_timer(1.0).timeout
	
	# Đợi thêm 0.5 giây trước khi xóa
	await get_tree().create_timer(0.5).timeout
	
	# Xóa boss
	print("Dead: Freeing boss")
	obj.queue_free()
