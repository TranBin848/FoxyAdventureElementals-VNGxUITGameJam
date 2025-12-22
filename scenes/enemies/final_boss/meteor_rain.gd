extends BlackEmperorState

@export var warning_scene: PackedScene
@export var meteor_skill: Skill  # Export skill để setup meteor
@export var meteor_count: int = 24  # Số lượng meteor
@export var arc_radius: float = 200.0  # Bán kính vòng cung (tăng lên để rộng hơn)
@export var meteor_spawn_delay: float = 0.2  # Delay giữa mỗi meteor
@onready var skill_factory: Node2DFactory = $"../../Direction/SkillFactory"

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
	
	# Spawn meteor theo thứ tự với delay
	for i in range(warning_positions.size()):
		var angle = angles[i]
		
		# Tính direction từ angle
		var dir = Vector2(cos(angle), sin(angle)).normalized()
		
		# Dùng _spawn_projectile để spawn meteor chuẩn
		var meteor = _spawn_projectile(meteor_skill, dir)
		
		#if meteor:
			## Tween meteor bay ra vị trí warning
			#var pos = warning_positions[i]
			#var tween = get_tree().create_tween()
			#tween.tween_property(meteor, "global_position", pos, 0.2)
		
		#await get_tree().create_timer(meteor_spawn_delay).timeout
	
	# Xóa các warning
	for warning in warnings:
		if is_instance_valid(warning):
			warning.queue_free()
	
	# Khôi phục trạng thái (giữ ignore_gravity = true để boss tiếp tục bay)
	obj.is_movable = true


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
	
func _spawn_projectile(skill: Skill, dir: Vector2) -> Area2D:
	var proj_node: Node = skill.projectile_scene.instantiate() if skill.projectile_scene else (skill_factory.create() if skill_factory else null)
	if not proj_node: return null
	var proj = proj_node as Area2D
	if proj == null: return null

	if proj.has_method("setup"): proj.setup(skill, dir)
	else:
		if proj.has_variable("speed"): proj.speed = skill.speed
		if proj.has_variable("damage"): proj.damage = skill.damage
		if proj.has_variable("direction"): proj.direction = dir
	proj.global_position = skill_factory.global_position
	get_tree().current_scene.add_child(proj)
	return proj
