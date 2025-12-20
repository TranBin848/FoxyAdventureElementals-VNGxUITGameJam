extends Resource
class_name Skill

## 🧙 Cấu trúc cơ bản cho mọi loại skill
@export var name: String
@export var element: ElementsEnum.Elements = ElementsEnum.Elements.NONE
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

@export var type: String = "single_shot" 

# có thể là: "single_shot", "multi_shot", "radial", "area", "buff"

func apply_to_button(button: TextureButton):
	button.cooldown.max_value = cooldown
	button.timer.wait_time = cooldown
	
	# SAFE texture load
	if texture_path and texture_path.strip_edges() != "":
		button.texture_normal = load(texture_path)
	else:
		button.texture_normal = null  # or preload("res://icon.svg")
	
	if button.has_method("update_stack_ui"):
		button.update_stack_ui()
	
func cast_spell(_caster: Node2D):
	#print("%s (%s) casted by %s" % [name, element, _caster.name])
	return self
