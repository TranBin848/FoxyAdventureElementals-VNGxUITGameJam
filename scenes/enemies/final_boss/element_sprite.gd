extends Sprite2D

## Sprite hiển thị icon nguyên tố, phóng to lên toàn màn hình rồi mờ dần

# 5 đường dẫn icon nguyên tố 48x48
# TODO: Thay đổi các path này thành đường dẫn icon thật của bạn
const ELEMENT_ICONS = {
	"metal": "res://assets/skills/icon element/Metal.png",  # Kim
	"wood": "res://assets/skills/icon element/wood.png",    # Mộc
	"water": "res://assets/skills/icon element/Water.png",  # Thủy
	"fire": "res://assets/skills/icon element/Fire.png",    # Hỏa
	"earth": "res://assets/skills/icon element/Earth.png"   # Thổ
}

func set_element(element_key: String) -> bool:
	"""
	Set icon dựa trên element type
	Returns true nếu load thành công
	"""
	if not ELEMENT_ICONS.has(element_key):
		print("Warning: Unknown element key: ", element_key)
		return false
	
	var icon_path = ELEMENT_ICONS[element_key]
	
	# Kiểm tra file có tồn tại không
	if not ResourceLoader.exists(icon_path):
		print("Warning: Element icon not found at ", icon_path)
		return false
	
	# Load texture
	var loaded_texture = load(icon_path) as Texture2D
	if not loaded_texture:
		print("Warning: Failed to load texture at ", icon_path)
		return false
	
	texture = loaded_texture
	return true

func play_zoom_fade_effect(duration: float = 1.5) -> void:
	"""
	Phóng to icon từ 48x48 lên toàn màn hình, sau đó mờ dần
	"""
	# Bắt đầu từ scale 1.0 (48x48)
	scale = Vector2.ONE
	modulate = Color.WHITE  # Opacity 100%
	
	# Lấy viewport size để tính scale cần thiết
	var viewport_size = get_viewport_rect().size
	# Giả sử icon 48x48, để phủ toàn màn hình (ví dụ 1920x1080) cần scale ~40x
	var target_scale = max(viewport_size.x / 48.0, viewport_size.y / 48.0) * 1.2  # Thêm 20% để chắc chắn phủ hết
	
	# Tween cho zoom
	var tween = create_tween()
	tween.set_parallel(true)  # Chạy song song
	
	# Zoom scale
	tween.tween_property(self, "scale", Vector2.ONE * target_scale, duration).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	
	# Fade out (bắt đầu fade từ 60% thời gian)
	tween.tween_property(self, "modulate:a", 0.0, duration * 0.6).set_delay(duration * 0.4).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	
	await tween.finished
	
	# Xóa sau khi xong
	queue_free()
