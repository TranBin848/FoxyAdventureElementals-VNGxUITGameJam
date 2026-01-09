extends PelicanState

func _enter() -> void:
	obj.change_animation("moving")

func _update(_delta: float) -> void:
	if obj.is_frozen: return
	control_moving()
	control_flying_away()
