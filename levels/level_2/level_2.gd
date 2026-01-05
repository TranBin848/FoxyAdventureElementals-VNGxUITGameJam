extends Node

func _enter_tree() -> void:
	# Handle portal spawning first
	GameManager.current_stage = self
	GameManager.current_level = 2
	GameManager.minimap = find_child("Minimap")
	
func _ready() -> void:
	if AudioManager:
		AudioManager.play_music("music_background")
		AudioManager.play_ambience("ambience_forest")

	#var skill_names = ["Thousand Swords", "Wooden Clone", "Earthquake", "Tornado"]
	#
	#for i in skill_names.size():
		## 🔥 Validate + equip
		#var skill = SkillDatabase.get_skill_by_name(skill_names[i])
		#if skill:
			#SkillTreeManager.unlock_skill(skill_names[i],0)
			#SkillTreeManager.equip_skill(i, skill_names[i])
			#print("✅ Equipped %s to slot %d" % [skill_names[i], i])
