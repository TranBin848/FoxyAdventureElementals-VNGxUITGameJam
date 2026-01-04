extends PlayerState

func _enter():
	#change animation to dead
	obj.change_animation("dead")
	obj.velocity.x = 0
	timer = 3


func _update(delta: float):
	if update_timer(delta):
		#GameManager.isReloadScene = true
		GameManager.change_stage(get_tree().current_scene.get_scene_file_path())

# Ignore take damage
func take_damage(direction: Variant, _damage: int = 1) -> void:
	pass
