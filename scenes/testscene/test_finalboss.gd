extends Node2D

func _ready() -> void:
	var skill_names = ["Stun Shot", "Thunderbolt", "Heal Over Time", "Thousand Swords", "Comet Rain"]
	ThousandSwords
	for i in skill_names.size():
		# 🔥 Validate + equip
		var skill = SkillDatabase.get_skill_by_name(skill_names[i])
		if skill:
			SkillTreeManager.unlock_skill(skill_names[i])
			SkillTreeManager.equip_skill(i, skill_names[i])
			print("✅ Equipped %s to slot %d" % [skill_names[i], i])
