extends Node

# ✅ 5 LEVELS - Controls which skills drop (not skill level!)
@export_group("Level Weights")
@export var level1_weights: Array[float] = [70.0, 20.0, 10.0]  # 70% skill1, 20% skill2, 10% skill3
@export var level2_weights: Array[float] = [50.0, 35.0, 15.0]
@export var level3_weights: Array[float] = [30.0, 40.0, 30.0]
@export var level4_weights: Array[float] = [20.0, 35.0, 45.0]
@export var level5_weights: Array[float] = [10.0, 30.0, 60.0]  # Heavy skill3

# ✅ SKILLS REFERENCE - Multiple per element
var elemental_tables: Dictionary = {
	ElementsEnum.Elements.FIRE: [
		preload("res://scenes/skills/scripts/fire/Fireball.gd"),
		preload("res://scenes/skills/scripts/fire/FireShot.gd"), 
		preload("res://scenes/skills/scripts/fire/FireExplosion.gd")
	],
	ElementsEnum.Elements.WATER: [
		preload("res://scenes/skills/scripts/water/WaterBall.gd"),
		preload("res://scenes/skills/scripts/water/WaterSpike.gd"),
		preload("res://scenes/skills/scripts/water/Tornado.gd")
	],
	ElementsEnum.Elements.WOOD: [
		preload("res://scenes/skills/scripts/wood/HealOverTime.gd"),
		preload("res://scenes/skills/scripts/wood/WoodenClone.gd"),
		preload("res://scenes/skills/scripts/wood/ToxicBreath.gd")
	],
	ElementsEnum.Elements.EARTH: [
		preload("res://scenes/skills/scripts/earth/Earthquake.gd"),
		preload("res://scenes/skills/scripts/earth/Burrow.gd"),
		preload("res://scenes/skills/scripts/earth/CometRain.gd")
	],
	ElementsEnum.Elements.METAL: [
		preload("res://scenes/skills/scripts/metal/ThunderStrike.gd"),
		preload("res://scenes/skills/scripts/metal/Thunderbolt.gd"),
		preload("res://scenes/skills/scripts/metal/ThousandSwords.gd")
	],
	ElementsEnum.Elements.NONE: []
}

var current_level: int = 0  # 0=Level1, 1=Level2, ..., 4=Level5
signal level_changed(new_level: int)

func _ready():
	print("✅ SkillDropManager loaded %d elemental tables" % elemental_tables.size())
	debug_print_tables()

# ✅ Get skill weights by current level (0-4)
func _get_level_weights() -> Array[float]:
	match current_level:
		0: return level1_weights
		1: return level2_weights
		2: return level3_weights
		3: return level4_weights
		4: return level5_weights
		_: return [50.0, 30.0, 20.0]  # Default

# ✅ Element → Weighted skill selection → Returns base skill resource
# Note: Skill power comes from SkillTreeManager level, NOT drop level
func roll_skill_drop(enemy_element: int) -> Skill:
	var rng = RandomNumberGenerator.new()
	rng.randomize()

	# 1. Get element's skill table (FIXED ORDER: [skill1, skill2, skill3])
	var table = elemental_tables.get(enemy_element, elemental_tables[ElementsEnum.Elements.NONE])
	if table.is_empty():
		return null
	
	# 2. Pick SPECIFIC SKILL by level weights
	var weights = _get_level_weights()
	var total_weight: float = 0.0
	for w in weights: 
		total_weight += w
	if total_weight == 0:
		return null
	
	var skill_index = rng.rand_weighted(weights)
	var skill_script: Script = table[skill_index]
	var skill_resource = skill_script.new() as Skill
	if not skill_resource:
		return null
	
	# 3. Return base skill - NO LEVEL ASSIGNMENT
	# The skill's power will come from SkillTreeManager.get_level(skill.name)
	
	print("🎲 Level%d %s → %s (%.0f%% drop chance)" % [
		current_level + 1,
		ElementsEnum.Elements.keys()[enemy_element],
		skill_resource.name, 
		weights[skill_index]
	])
	
	return skill_resource

func set_level(level: int):
	current_level = clamp(level, 0, 4)
	level_changed.emit(current_level)
	
	var weights = _get_level_weights()
	print("📊 Drop Level %d set (skill1:%.0f%% skill2:%.0f%% skill3:%.0f%%)" % [
		level + 1, 
		weights[0], weights[1], weights[2]
	])

func debug_print_tables():
	print("=== SKILL DROP TABLES ===")
	for element in elemental_tables:
		var skills = elemental_tables[element]
		if not skills.is_empty():
			var skill_names = []
			for i in range(skills.size()):
				var skill = skills[i].new() as Skill
				skill_names.append("skill%d=%s" % [i+1, skill.name])
			print("%s: %d skills [%s]" % [
				ElementsEnum.Elements.keys()[element], 
				skills.size(),
				", ".join(skill_names)
			])