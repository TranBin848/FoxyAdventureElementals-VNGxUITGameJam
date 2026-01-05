extends Node

var my_logger: Logger = ConsoleLogger.new()

func _enter_tree() -> void:
	# Handle portal spawning first
	GameManager.current_stage = self
	GameManager.current_level = 1
	GameManager.minimap = find_child("Minimap")
	
func _ready() -> void:
	#if not GameManager.respawn_at_portal():
		#GameManager.respawn_at_checkpoint()
		#await GameManager.checkpoint_loading_complete
	
	# Now safe to add coins
	#GameManager.inventory_system.add_coin(500)
	if AudioManager:
		AudioManager.play_music("music_background")
		AudioManager.play_ambience("ambience_forest", -10)
		
	var skill_names = ["Thousand Swords", "Wooden Clone", "Earthquake", "Tornado", "Fireball"]
	
	for i in skill_names.size():
		# 🔥 Validate + equip
		var skill = SkillDatabase.get_skill_by_name(skill_names[i])
		if skill:
			SkillTreeManager.unlock_skill(skill_names[i],0)
			SkillTreeManager.equip_skill(i, skill_names[i])
			print("✅ Equipped %s to slot %d" % [skill_names[i], i])
			
	#GameManager.logger.log("Hi Im global logger, Im from level 1")
	#my_logger.log("Hi Im script-level logger, Im from level 1")
	
	#Dialogic.start("sail_boat")
	
