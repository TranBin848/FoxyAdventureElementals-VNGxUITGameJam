extends Node

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
		"Wooden Clone": WoodenClone,
		"Stun Shot": StunShot,
		"Thunder Strike": Thunderbolt,
		"Earthquake": Earthquake,
		"Comet Rain": CometRain,
		"Burrow": Burrow
	}
	
func get_skill_by_name(_name: String) -> Skill:
	if _name in all_skills:
		var skill_instance = all_skills[_name].new() as Skill
		return skill_instance
	return null
