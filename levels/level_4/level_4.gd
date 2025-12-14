extends Node

func _enter_tree() -> void:
	# Handle portal spawning first
	GameManager.current_stage = self

	
func _ready() -> void:
	if not GameManager.respawn_at_portal():
		GameManager.respawn_at_checkpoint()
	if AudioManager:
		AudioManager.play_music("music_background")
		AudioManager.play_ambience("ambience_forest")
