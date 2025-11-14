extends ParallaxLayer

func _process(delta: float) -> void:
	motion_offset.x -= delta * 45
