extends Node

var my_logger: Logger = NoLogger.new()

func _enter_tree() -> void:
	# Handle portal spawning first
	GameManager.current_stage = self
	
func _ready() -> void:
	if not GameManager.respawn_at_portal():
		GameManager.respawn_at_checkpoint()
	
	GameManager.logger.log("Hi Im global logger, Im from level 1")
	my_logger.log(("Hi Im script-level logger, Im from level 1"))
	
