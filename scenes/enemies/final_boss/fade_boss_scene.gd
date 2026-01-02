extends ColorRect

## ColorRect tạo hiệu ứng flash (ánh sáng lóe lên rồi mờ đi)

func play_flash_effect(duration: float = 0.5) -> void:
	"""
	Tạo hiệu ứng flash: fade in nhanh -> fade out
	"""
	# Hiện ra
	visible = true
	modulate.a = 0.0
	
	var tween = create_tween()
	tween.set_ease(Tween.EASE_OUT)
	tween.set_trans(Tween.TRANS_CUBIC)
	
	# Fade in nhanh (30% thời gian)
	tween.tween_property(self, "modulate:a", 1.0, duration * 0.3)
	# Fade out chậm hơn (70% thời gian)
	tween.tween_property(self, "modulate:a", 0.0, duration * 0.7)
	
	await tween.finished
	
	# Ẩn đi sau khi xong
	visible = false
