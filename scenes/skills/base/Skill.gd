# res://skills/base/Skill.gd
extends Resource
class_name Skill

## 🧙 Cấu trúc cơ bản cho mọi loại skill
@export var name: String
@export var element: String = "Fire" # Fire, Water, Earth, Metal, Wood
@export var cooldown: float = 1.0
@export var texture: Texture2D
@export var animation_name: String
@export var projectile_scene: PackedScene = null
@export var speed: float = 250
@export var damage: int = 10
@export var sound_effect: AudioStream = null

@export var type: String = "single_shot" 
# có thể là: "single_shot", "multi_shot", "radial", "melee", "buff"

func apply_to_button(button: TextureButton):
	button.cooldown.max_value = cooldown
	button.texture_normal = texture
	button.timer.wait_time = cooldown

func cast_spell(caster: Node2D):
	print("%s (%s) casted by %s" % [name, element, caster.name])
	return self
