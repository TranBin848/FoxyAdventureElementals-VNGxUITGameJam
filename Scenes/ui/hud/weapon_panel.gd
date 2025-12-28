extends PanelContainer
class_name WeaponPanel

@onready var texture_rect: TextureRect = $TextureRect

const TEXTURE_BLADE = preload("res://assets/island/images/blade/blade_icon.png")
const TEXTURE_WAND = preload("res://assets/foxy/fox_hat_wand/wand.png")

const SLIDE_DURATION: float = 0.25
const SLIDE_DISTANCE: float = 100.0

# Biến để lưu Texture tiếp theo
var next_texture: Texture2D = null

func _ready() -> void:
	# 1. Tìm Player
	var player = get_tree().get_first_node_in_group("player")
	if player:
		# 2. Lắng nghe tín hiệu đổi vũ khí từ Player
		# Chúng ta cần Player phát ra một signal khi đổi vũ khí
		player.connect("weapon_swapped", _on_weapon_swapped)
	texture_rect.modulate.a = 1.0
	
	
func _on_weapon_swapped(equipped_weapon_type: String):
	# 1. Xác định Texture mới
	match equipped_weapon_type:
		"blade":
			next_texture = TEXTURE_BLADE
		"wand":
			next_texture = TEXTURE_WAND
		"normal":
			next_texture = null
		_:
			return

	# 🎯 FIX: GỌI HÀM CẬP NHẬT NGAY LẬP TỨC
	_update_texture_instantly()


func _update_texture_instantly():
	texture_rect.modulate.a = 1.0 

	if next_texture:
		texture_rect.texture = next_texture
	else:
		texture_rect.texture = null
