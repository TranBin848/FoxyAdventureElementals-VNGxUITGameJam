extends EnemyState

@export var despawn_time: float = 0.6

func _enter() -> void:
	obj.change_animation("dead")
	obj.velocity.x = 0
	obj.disable_collision()
	timer = despawn_time

func _update( _delta ):
	if update_timer(_delta):
		obj.queue_free()
	super._update(_delta)
