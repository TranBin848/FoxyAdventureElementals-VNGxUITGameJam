extends Node

func _ready() -> void:
	GameManager.current_level = 6
	if AudioManager:
		AudioManager.play_music("music_background")
		AudioManager.play_ambience("ambience_forest", -10)
		
	GameManager.current_stage = self
	GameManager.player.collect_wand()
	var skill_names = ["Thousand Swords", "Earthquake", "Thunder Strike", "Burrow", "Fireball"]
	for i in skill_names.size():
		# 🔥 Validate + equip
		var skill = SkillDatabase.get_skill_by_name(skill_names[i])
		if skill:
			SkillTreeManager.unlock_skill(skill_names[i])
			SkillTreeManager.equip_skill(i, skill_names[i])
			SkillTreeManager._set_level(skill_names[i],10)
			print("✅ Equipped %s to slot %d" % [skill_names[i], i])
