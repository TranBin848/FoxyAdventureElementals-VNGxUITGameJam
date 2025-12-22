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
	var target_fly_pos = start_pos + Vector2(0, -fly_height)
	
	# Tắt gravity và di chuyển trong khi bay
	obj.ignore_gravity = true
	obj.is_movable = false
	
	# Play animation bay nếu có
	if obj.animated_sprite_2d and obj.animated_sprite_2d.sprite_frames.has_animation("fly"):
		obj.animated_sprite_2d.play("fly")
	
	# Bay lên trời bằng Tween
	var tween = get_tree().create_tween()
	tween.tween_property(obj, "global_position", target_fly_pos, fly_duration).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	await tween.finished
	
	# Tạo 6 vị trí warning: 3 bên trái, 3 bên phải boss
	var warning_positions = []
	var spacing = 135  # Khoảng cách giữa các warning
	
	# 3 vị trí bên trái boss
	for i in range(3):
		var offset = (i + 1) * spacing
		
		warning_positions.append(start_pos + Vector2(-offset, offsety))
	
	# 3 vị trí bên phải boss
	for i in range(3):
		var offset = (i + 1) * spacing
		warning_positions.append(start_pos + Vector2(offset, offsety))
	
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
		change_state(fsm.states.idle)
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
	
	# Gọi use_skill để tự động chuyển sang skill tiếp theo
	obj.use_skill()

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
