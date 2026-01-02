extends Node

func _enter_tree() -> void:
	# Handle portal spawning first
	GameManager.current_stage = self
	GameManager.current_level = 3
	
func _ready() -> void:
	#if not GameManager.respawn_at_portal():
		#GameManager.respawn_at_checkpoint()
	pass
