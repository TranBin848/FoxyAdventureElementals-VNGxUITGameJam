extends Resource
class_name Skill

## 🧙 Cấu trúc cơ bản cho mọi loại skill
@export var name: String
@export var element: ElementsEnum.Elements = ElementsEnum.Elements.NONE
@export var cooldown: float = 1.0
@export var duration: float = 1.0
@export var hit_delay: float = 0.0
@export var texture_path: String
@export var animation_name: String
@export var projectile_scene: PackedScene = null
@export var area_scene: PackedScene = null
@export var speed: float = 250
@export var damage: int = 10
@export var sound_effect: AudioStream = null
@export var mana: int = 1.0

@export var type: String = "single_shot" 

var texture = load(texture_path)
# có thể là: "single_shot", "multi_shot", "radial", "area", "buff"

#Thêm trường mã hóa element để tiện xử lý logic
# 0: None, 1: Fire, 2: Water, 3: Earth, 4: Metal, 5: Wood
var elemental_type: int:
	get:
		match element:
			"Fire": return 1
			"Earth": return 2
			"Water": return 3
			"Metal": return 4
			"Wood": return 5
			_: return 0

func apply_to_button(button: TextureButton):
	button.cooldown.max_value = cooldown
	button.texture_normal = load(texture_path)
	button.timer.wait_time = cooldown
	if button.has_method("update_stack_ui"):
		#Hàm này chỉ tồn tại trong lớp SpellButton mở rộng
		button.update_stack_ui()
	
func cast_spell(caster: Node2D):
	#print("%s (%s) casted by %s" % [name, element, caster.name])
	return self
