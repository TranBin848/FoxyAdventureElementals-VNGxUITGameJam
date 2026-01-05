extends Resource
class_name Skill

## 🧙 Cấu trúc cơ bản cho mọi loại skill
@export var name: String
@export var elemental_type: ElementsEnum.Elements = ElementsEnum.Elements.NONE
@export var level: int = 1  # ✅ NEW: Skill level from drops (1-3)
@export var cooldown: float = 1.0
@export var duration: float = 1.0
@export var hit_delay: float = 0.0
@export var ground_targeted: bool = false  # Set TRUE for CometRain
@export var texture_path: String
@export var animation_name: String
@export var projectile_scene: PackedScene = null
@export var area_scene: PackedScene = null
@export var speed: float = 250
@export var damage: float = 10.0
@export var sound_effect: AudioStream = null
@export var mana: int = 1

@export var type: String = "single_shot"  # "single_shot", "multi_shot", "radial", "area", "buff", "ultimate"

# ✅ LEVEL SCALING (auto-applies in getters)
func get_scaled_cooldown() -> float:
	return cooldown / (1.0 + (level - 1) * 0.2)  # Lv1=100%, Lv2=83%, Lv3=67%

func get_scaled_damage() -> float:
	return damage * (1.0 + (level - 1) * 0.3)  # Lv1=100%, Lv2=130%, Lv3=160%

func get_scaled_mana() -> int:
	return max(1, mana + (level - 1))  # Lv1=base, Lv2=base+1, Lv3=base+2

func get_scaled_speed() -> float:
	return speed * (1.0 + (level - 1) * 0.15)  # Lv1=100%, Lv2=115%, Lv3=130%

# Display name with level
func get_display_name() -> String:
	return "%s Lv%d" % [name, level]

func apply_to_button(button: TextureButton):
	button.cooldown.max_value = get_scaled_cooldown()
	button.timer.wait_time = get_scaled_cooldown()
	
	# SAFE texture load + level display
	if texture_path and texture_path.strip_edges() != "":
		button.texture_normal = load(texture_path)
	else:
		button.texture_normal = null
	
	# Update stack UI with level info
	if button.has_method("update_stack_ui"):
		button.update_stack_ui()
	
	# Optional: Set button tooltip with level stats
	if button.has_method("set_tooltip_text"):
		button.tooltip_text = "%s\nDamage: %.1f | Cooldown: %.1fs | Lv%d" % [
			get_display_name(),
			get_scaled_damage(),
			get_scaled_cooldown(),
			level
		]

func cast_spell(_caster: Node2D):
	# Use scaled values in actual casting (your player logic)
	print("🧙 %s casted (Lv%d, DMG:%.1f, CD:%.1fs)" % [
		name, level,
		get_scaled_damage(),
		get_scaled_cooldown()
	])
	return self
