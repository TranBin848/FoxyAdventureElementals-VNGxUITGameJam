extends Node2D

# Tốc độ zoom (có thể chỉnh trong Inspector)
@export var zoom_speed: float = 1.0
@export var min_zoom: float = 0.2
@export var max_zoom: float = 5.0

# Tốc độ kéo (có thể chỉnh)
@export var pan_speed: float = 1.0

var _is_dragging: bool = false
var _last_drag_position: Vector2

@onready var camera: Camera2D = $Camera2D

func _ready():
	# Bật input cho camera
	camera.enabled = true

func _unhandled_input(event):
	# === ZOOM bằng bánh xe ===
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			_zoom_at_point(zoom_speed, event.position)
			get_viewport().set_input_as_handled()
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			_zoom_at_point(-zoom_speed, event.position)
			get_viewport().set_input_as_handled()
			
		# Bắt đầu/kết thúc kéo
		elif event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				_is_dragging = true
				_last_drag_position = event.position
			else:
				_is_dragging = false

	# === PAN (kéo di chuyển) ===
	elif event is InputEventMouseMotion and _is_dragging:
		var delta = event.position - _last_drag_position
		# Di chuyển camera ngược lại với hướng kéo
		camera.position -= delta * pan_speed / camera.zoom.x
		_last_drag_position = event.position
		get_viewport().set_input_as_handled()

# Hàm zoom vào đúng vị trí con trỏ chuột (trải nghiệm mượt nhất)
func _zoom_at_point(zoom_change: float, point: Vector2):
	var old_zoom = camera.zoom.x
	var new_zoom = clamp(old_zoom + zoom_change, min_zoom, max_zoom)
	
	if new_zoom == old_zoom:
		return
		
	camera.zoom = Vector2(new_zoom, new_zoom)
	
	# Tính toán để điểm dưới con trỏ không bị dịch chuyển khi zoom
	var viewport_center = camera.get_screen_center_position()
	var offset = point - viewport_center
	camera.position += offset * (1.0 - old_zoom / new_zoom)
