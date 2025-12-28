extends Node

@onready var player: CharacterBody2D = null
var has_killed_player: bool = false

func _enter_tree() -> void:
	# Handle portal spawning first
	GameManager.current_stage = self
	GameManager.current_level = 2
	GameManager.minimap = find_child("Minimap")
	# ✅ Wait 1 frame for enemies to spawn
	await get_tree().process_frame
	
	# Scale health
	GameManager.scale_health()

	
func _ready() -> void:
	# Reset the flag when entering/respawning in the level
	has_killed_player = false
	
	if not GameManager.respawn_at_portal():
		GameManager.respawn_at_checkpoint()
	if AudioManager:
		AudioManager.play_music("music_background")
		AudioManager.play_ambience("ambience_forest")
	
	# Get player reference
	player = get_tree().get_first_node_in_group("player")
