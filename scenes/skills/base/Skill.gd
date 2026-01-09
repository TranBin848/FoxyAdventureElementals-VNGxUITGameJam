extends Resource
class_name Skill

## 🧙 Cấu trúc cơ bản cho mọi loại skill
@export var name: String
@export var elemental_type: ElementsEnum.Elements = ElementsEnum.Elements.NONE
@export var cooldown: float = 1.0
@export var duration: float = 1.0
@export var hit_delay: float = 0.0
@export var ground_targeted: bool = false  # Set TRUE for CometRain
@export var texture_path: String
@export var animation_name: String
@export var projectile_scene_path: String = ""
@export var area_scene_path: String = ""
@export var speed: float = 250
@export var damage: float = 10.0
@export var sound_effect: AudioStream = null
@export var mana: int = 1

@export var type: String = "single_shot"  # "single_shot", "multi_shot", "radial", "area", "buff", "ultimate"

# ✅ SCALING FORMULA - Adjust multiplier here to control max level power
const SCALE_MULTIPLIER: float = 0.5  # At level 10: base × (1 + √9 × 0.5) = base × 2.5

# Helper function to calculate scaling based on SkillTreeManager level
func _calculate_scale() -> float:
	if not SkillTreeManager:
		return 1.0
	
	var skill_level = SkillTreeManager.get_level(name)
	if skill_level <= 1:
		return 1.0
	
	return 1.0 + sqrt(skill_level - 1) * SCALE_MULTIPLIER

# ✅ AUTO-SCALED GETTERS (uses SkillTreeManager level)
func get_scaled_damage() -> float:
	return damage * _calculate_scale()

func get_scaled_mana() -> int:
	return int(ceil(mana * _calculate_scale()))

func get_scaled_duration() -> float:
	return duration * _calculate_scale()

func get_scaled_speed() -> float:
	return speed * _calculate_scale()

func get_scaled_cooldown() -> float:
	# Cooldown typically doesn't scale, but you can enable it if needed
	return cooldown

# Display name with level from SkillTreeManager
func get_display_name() -> String:
	if not SkillTreeManager:
		return name
	var skill_level = SkillTreeManager.get_level(name)
	return "%s Lv%d" % [name, skill_level]

func apply_to_button(button: TextureButton):
	button.cooldown.max_value = get_scaled_cooldown()
	button.timer.wait_time = get_scaled_cooldown()
	
	# SAFE texture load
	if texture_path and texture_path.strip_edges() != "":
		button.texture_normal = load(texture_path)
	else:
		button.texture_normal = null
	
	# Update stack UI with level info
	if button.has_method("update_stack_ui"):
		button.update_stack_ui()
	
	# Optional: Set button tooltip with level stats
	if button.has_method("set_tooltip_text"):
		var skill_level = SkillTreeManager.get_level(name) if SkillTreeManager else 1
		button.tooltip_text = "%s\nDamage: %.1f | Cooldown: %.1fs | Lv%d" % [
			name,
			get_scaled_damage(),
			get_scaled_cooldown(),
			skill_level
		]

func cast_spell(_caster: Node2D):
	# Use scaled values in actual casting
	var skill_level = SkillTreeManager.get_level(name) if SkillTreeManager else 1
	print("🧙 %s casted (Lv%d, DMG:%.1f, CD:%.1fs)" % [
		name, skill_level,
		get_scaled_damage(),
		get_scaled_cooldown()
	])
	return self
