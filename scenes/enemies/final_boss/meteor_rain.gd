extends BlackEmperorState

@export var warning_scene: PackedScene
@export var star_scene: PackedScene  # Scene ngôi sao bay lên trước
@export var meteor_scene: PackedScene  # Scene fire shot projectile
@export var meteor_count: int = 24  # Số lượng meteor
@export var arc_radius: float = 200.0  # Bán kính vòng cung (tăng lên để rộng hơn)
@export var meteor_spawn_delay: float = 0.2  # Delay giữa mỗi meteor
@export var meteor_speed: float = 300.0  # Tốc độ meteor
@export var meteor_damage: int = 15  # Damage của meteor

func _enter():
	# Lấy vị trí boss
	var boss_pos = obj.global_position
	
	# Tắt gravity và di chuyển để boss tiếp tục bay
	obj.ignore_gravity = true
	obj.is_movable = false
	obj.velocity.x = 0
	
	# Play animation nếu có
	if obj.animated_sprite_2d and obj.animated_sprite_2d.sprite_frames.has_animation("cast"):
		obj.animated_sprite_2d.play("cast")
	
	# Bắn ngôi sao lên trên đầu boss
	var star_target_pos = boss_pos + Vector2(0, -75)  # Vị trí phía trên boss
	var star = _spawn_star(star_target_pos)
	# Chờ ngôi sao bay đến vị trí
	if star:
		var tween = get_tree().create_tween()
		tween.tween_property(star, "global_position", star_target_pos, 0.5)
		await tween.finished
		
		# Cập nhật boss_pos thành vị trí ngôi sao
		boss_pos = star.global_position
	
	# Tạo các vị trí warning theo hình vòng tròn đầy đủ (360 độ)
	var warning_positions = []
	var angles = []  # Lưu góc để xoay meteor sau
	
	for i in range(meteor_count):
		# Tính góc từ 0 đến 2*PI (360 độ) - vòng tròn đầy đủ
		var angle = (float(i) / float(meteor_count)) * TAU  # TAU = 2*PI
		angles.append(angle)
		
		# Tính vị trí theo vòng tròn
		var offset_x = cos(angle) * arc_radius
		var offset_y = sin(angle) * arc_radius
		
		var warning_pos = boss_pos + Vector2(offset_x, offset_y)
		warning_positions.append(warning_pos)
	
	# Tạo các warning
	var warnings = []
	for pos in warning_positions:
		var warning = warning_scene.instantiate()
		warning.global_position = pos
		warning.visible = false
		get_tree().current_scene.add_child(warning)
		warnings.append(warning)
	
	# Chớp chớp các warning
	await alert_coroutine(warnings)
	
	# Kiểm tra phase
	if obj.current_phase != obj.Phase.FLY:
		for warning in warnings:
			if is_instance_valid(warning):
				warning.queue_free()
		obj.is_movable = true
		change_state(fsm.states.idle)
		return
	
	# Spawn tất cả meteor cùng lúc
	for i in range(warning_positions.size()):
		var angle = angles[i]
		
		# Tính direction từ angle
		var dir = Vector2(cos(angle), sin(angle)).normalized()
		
		# Spawn meteor từ vị trí boss/star
		var meteor = _spawn_meteor(boss_pos, dir)
	
	# Xóa các warning
	for warning in warnings:
		if is_instance_valid(warning):
			warning.queue_free()
	
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

func _spawn_star(target_pos: Vector2) -> Node2D:
	if not star_scene:
		return null
	
	var star = star_scene.instantiate() as Node2D
	if not star:
		return null
	
	star.global_position = obj.global_position
	get_tree().current_scene.add_child(star)
	return star

func _spawn_meteor(spawn_pos: Vector2, dir: Vector2) -> Area2D:
	if not meteor_scene:
		return null
	
	var meteor = meteor_scene.instantiate() as Area2D
	if not meteor:
		return null
	
	# Set properties
	if "direction" in meteor:
		meteor.direction = dir
	if "speed" in meteor:
		meteor.speed = meteor_speed
	if "damage" in meteor:
		meteor.damage = meteor_damage
	
	# Scale projectile lên x1.25
	meteor.scale = Vector2(1.25, 1.25)
	
	# Set vị trí và rotation
	meteor.global_position = spawn_pos
	meteor.rotation = dir.angle()
	
	get_tree().current_scene.add_child(meteor)
	return meteor
