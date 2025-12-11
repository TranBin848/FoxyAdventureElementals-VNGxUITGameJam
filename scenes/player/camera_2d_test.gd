extends Camera2D

var zoom_minimum := Vector2(0.5, 0.5)
var zoom_maximum := Vector2(3.5, 3.5)
var zoom_speed := 0.2

var dragging := false
var last_mouse_pos := Vector2.ZERO

@onready var camera: Camera2D = $"."
#@onready var info_panel: SkillInfoPanel

#func _ready() -> void:
	#camera.make_current()

func _input(event: InputEvent) -> void:
	#Uncomment to enable this to ZOOM MAP
	#return
	# --- ZOOM ---
	# Nếu panel mở → KHÔNG ZOOM, KHÔNG DRAG
	#if info_panel.visible:
		#return
	
	if event is InputEventMouseButton:
		if event.is_pressed():	
			if event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
				_apply_zoom(-zoom_speed)

			if event.button_index == MOUSE_BUTTON_WHEEL_UP:
				_apply_zoom(zoom_speed)

	# --- DRAG START ---
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			dragging = event.is_pressed()
			last_mouse_pos = get_viewport().get_mouse_position()

	# --- DRAG MOVE ---
	if event is InputEventMouseMotion and dragging:
		var mouse_pos = get_viewport().get_mouse_position()
		var delta = mouse_pos - last_mouse_pos
		camera.global_position -= delta / camera.zoom
		last_mouse_pos = mouse_pos


# ===========================
#      HÀM ZOOM GỌN GÀNG
# ===========================
func _apply_zoom(delta: float) -> void:
	var new_zoom = camera.zoom + Vector2(delta, delta)
	new_zoom.x = clamp(new_zoom.x, zoom_minimum.x, zoom_maximum.x)
	new_zoom.y = clamp(new_zoom.y, zoom_minimum.y, zoom_maximum.y)
	camera.zoom = new_zoom
