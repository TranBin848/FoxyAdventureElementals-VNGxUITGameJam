class_name Level0
extends Node

var my_logger: Logger = ConsoleLogger.new()
static var player: Player = null

func _enter_tree() -> void:
	# Handle portal spawning first
	GameManager.current_stage = self
	GameManager.current_level = 0
	
func _ready() -> void:
	if not GameManager.respawn_at_portal():
		GameManager.respawn_at_checkpoint()
	if AudioManager:
		AudioManager.play_music("ambience_beach")
		#AudioManager.play_ambience("ambience_forest", -10)
	#GameManager.logger.log("Hi Im global logger, Im from level 4")
	my_logger.log("Hi Im script-level logger, Im from level 0")
	
	player = $Player
	
	call_deferred("start_dialogue")

func start_dialogue():
	Dialogic.start("level_0")
	
