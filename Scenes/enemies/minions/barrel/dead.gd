extends EnemyState
@export var despawn_time: float = 2

func _enter() -> void:
	obj.change_animation("dead")
	obj.velocity.x = 0
	obj.disable_collision()
	timer = despawn_time
	
func _update( _delta ):
	if update_timer(_delta):
		obj.queue_free()

func take_damage(direction: Variant, damage: int = 1) -> void:
	pass
