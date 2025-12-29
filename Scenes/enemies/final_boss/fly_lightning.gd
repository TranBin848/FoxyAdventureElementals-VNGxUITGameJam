extends BlackEmperorState

@export var warning_scene: PackedScene
@export var lightning_scene: PackedScene
@export var fly_height: float = 150.0  # Độ cao boss bay lên
@export var fly_duration: float = 0.8  # Thời gian bay lên
var offsety = 20.0

@onready var skill_factory: Node2DFactory = $"../../Direction/SkillFactory"


func _enter():
	# Lưu vị trí ban đầu của boss
	var start_pos = obj.global_position
	
	# Chỉ bay lên nếu boss đang ở thấp, nếu đang cao rồi thì giữ nguyên
	var target_fly_pos = Vector2(start_pos.x, obj.fly_target_y)
	
	# Tắt gravity và di chuyển trong khi bay
	obj.ignore_gravity = true
	obj.is_movable = false
	
	# Play animation bay nếu có
	if obj.animated_sprite_2d and obj.animated_sprite_2d.sprite_frames.has_animation("fly"):
		obj.animated_sprite_2d.play("fly")
	
	# Bay lên độ cao cố định (nếu chưa đạt độ cao đó)
	if start_pos.y > obj.fly_target_y:
		var tween = get_tree().create_tween()
		tween.tween_property(obj, "global_position", target_fly_pos, fly_duration).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		await tween.finished
	else:
		# Đã ở độ cao rồi, giữ nguyên
		target_fly_pos = start_pos
	
	# Tạo 6 vị trí warning: 3 bên trái, 3 bên phải boss
	var warning_positions = []
	var spacing = 135  # Khoảng cách giữa các warning
	var current_x = obj.global_position.x  # Vị trí x hiện tại của boss
	var ground_y = obj.ground_y  # Độ cao mặt đất
	
	warning_positions.append(Vector2(current_x, ground_y + offsety))
	
	# 3 vị trí bên trái boss
	for i in range(4):
		var offset = (i + 1) * spacing
		warning_positions.append(Vector2(current_x - offset, ground_y + offsety))
	
	# 3 vị trí bên phải boss
	for i in range(4):
		var offset = (i + 1) * spacing
		warning_positions.append(Vector2(current_x + offset, ground_y + offsety))
	
	# Tạo các warning và lưu lại
	var warnings = []
	for pos in warning_positions:
		var warning = warning_scene.instantiate()
		warning.global_position = pos
		warning.visible = false  # Ẩn đi để chuẩn bị chớp
		get_tree().current_scene.add_child(warning)
		warnings.append(warning)
	
	# Chớp chớp các warning
	await alert_coroutine(warnings)
	
	# Kiểm tra phase vẫn còn FLY không
	if obj.current_phase != obj.Phase.FLY:
		# Xóa tất cả warnings
		for warning in warnings:
			if is_instance_valid(warning):
				warning.queue_free()
		obj.ignore_gravity = false
		obj.is_movable = true
		#change_state(fsm.states.idle)
		return
	
	# Thả lightning xuống tất cả các vị trí
	for pos in warning_positions:
		var lightning = lightning_scene.instantiate()
		lightning.global_position = pos
		get_tree().current_scene.add_child(lightning)
	
	# Xóa các warning
	for warning in warnings:
		if is_instance_valid(warning):
			warning.queue_free()
	
	## Bay xuống về vị trí ban đầu
	#var return_tween = get_tree().create_tween()
	#return_tween.tween_property(obj, "global_position", start_pos, fly_duration).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	#await return_tween.finished
	
	# Khôi phục trạng thái di chuyển
	obj.is_movable = true
	
	# Đợi 3 giây trước khi chuyển sang skill tiếp theo
	await get_tree().create_timer(3.0).timeout
	
	# Kiểm tra phase trước khi di chuyển
	if obj.current_phase != obj.Phase.FLY:
		# Đã chuyển phase, dừng hẳn
		return
	
	# Di chuyển qua lại trái phải dựa trên vị trí x ban đầu
	await _move_horizontally()
	
	# Kiểm tra phase lần nữa sau khi di chuyển xong
	if obj.current_phase != obj.Phase.FLY:
		return
	
	# Phase 1: tiếp tục skill tiếp theo
	obj.use_skill()

func _land_and_charge() -> void:
	# Hạ boss xuống mặt đất
	if obj.animated_sprite_2d and obj.animated_sprite_2d.sprite_frames.has_animation("land"):
		obj.animated_sprite_2d.play("land")
	
	var target_pos = Vector2(obj.global_position.x, obj.ground_y)
	var tween = create_tween()
	tween.tween_property(obj, "global_position", target_pos, 1.0).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	await tween.finished
	
	# Chuyển sang state charge
	if fsm.states.has("charge"):
		fsm.change_state(fsm.states.charge)
	else:
		obj.use_skill()

func _move_horizontally():
	# Lấy vị trí x ban đầu của boss
	var original_x = obj.original_x if "original_x" in obj else obj.global_position.x
	var current_x = obj.global_position.x
	var move_distance = 200.0  # Khoảng cách di chuyển
	var move_duration = 1.5  # Thời gian di chuyển
	
	# Xác định vị trí đích dựa trên vị trí hiện tại so với original
	var target_x: float
	if current_x < original_x:
		# Đang ở bên trái, di chuyển sang phải
		target_x = original_x + move_distance
	else:
		# Đang ở bên phải hoặc tại vị trí gốc, di chuyển sang trái
		target_x = original_x - move_distance
	
	# Thêm biến thiên độ cao cố định (lên hoặc xuống 25 pixels)
	var y_offset = 25.0 if randf() > 0.5 else -25.0
	var target_y = obj.global_position.y + y_offset
	
	# Tạo tween để di chuyển
	var target_pos = Vector2(target_x, target_y)
	var tween = get_tree().create_tween()
	tween.tween_property(obj, "global_position", target_pos, move_duration).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN_OUT)
	await tween.finished

func alert_coroutine(warnings: Array) -> void:
	var times = 5
	for i in times:
		await get_tree().create_timer(0.05).timeout
		# Hiện tất cả warnings
		for warning in warnings:
			if is_instance_valid(warning):
				warning.visible = true
		await get_tree().create_timer(0.25).timeout
		# Ẩn tất cả warnings
		for warning in warnings:
			if is_instance_valid(warning):
				warning.visible = false
