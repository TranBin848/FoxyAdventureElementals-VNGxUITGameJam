extends EnemyState

func _enter() -> void:
	obj.change_animation("attack")

func _update(_delta: float) -> void:
	pass
