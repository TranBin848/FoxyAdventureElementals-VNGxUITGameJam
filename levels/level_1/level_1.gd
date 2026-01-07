extends Node

func _ready() -> void:
	GameManager.current_level = 1
	if AudioManager:
		AudioManager.play_music("music_background")
		AudioManager.play_ambience("ambience_forest", -10)
