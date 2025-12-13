extends WarLordState

func _enter() -> void:
	obj.handle_dead()
	obj.change_animation("die")
