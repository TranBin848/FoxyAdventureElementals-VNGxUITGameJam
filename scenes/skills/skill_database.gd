extends Node
class_name SkillDatabase

var all_skills = {
		"Fire Explosion": FireExplosion, 
		"Fire Shot": FireShot,
		"Fire Ball": Fireball,
		"Water Ball": WaterBall,
		"Water Spike": WaterSpike, 
		"Tornado": Tornado,
		"Wood Shot": WoodShot,
		"Heal Over Time": HealOverTime,
		"Toxic Breath": ToxicBreath,
		"Stun Shot": StunShot,
		"Thunder Strike": Thunderbolt,
		"Earthquake": Earthquake
	}
func get_skill_by_name(name: String) -> Script:
	if name in all_skills:
		return all_skills[name]
	return null
