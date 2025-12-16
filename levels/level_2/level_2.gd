extends Node

@onready var player: CharacterBody2D = null
var has_killed_player: bool = false

func _enter_tree() -> void:
	# Handle portal spawning first
	GameManager.current_stage = self
	
func _ready() -> void:
	if not GameManager.respawn_at_portal():
		GameManager.respawn_at_checkpoint()
	if AudioManager:
		AudioManager.play_music("music_background")
		AudioManager.play_ambience("ambience_forest")
	
	# Get player reference
	player = get_tree().get_first_node_in_group("player")

func _process(delta: float) -> void:
	if player and not has_killed_player and player.global_position.y > 1050:
		# Kill player (only once)
		has_killed_player = true
		# Call take_damage through the FSM state to properly handle death transition
		if player.fsm and player.fsm.current_state:
			player.fsm.current_state.take_damage(Vector2.DOWN, player.max_health + 1)
