extends BlackEmperorState

@export var warning_scene: PackedScene
@export var star_scene: PackedScene  # Scene ngôi sao bay lên trước
@export var meteor_scene: PackedScene  # Scene fire shot projectile
@export var shot_count: int = 5  # Số lần bắn
@export var shots_per_burst: int = 3  # Số đạn mỗi lần bắn
@export var burst_delay: float = 0.15  # Delay giữa các đạn trong 1 burst
@export var shot_interval: float = 1.0  # Thời gian giữa các lần bắn
@export var meteor_speed: float = 400.0  # Tốc độ meteor
@export var meteor_damage: int = 15  # Damage của meteor
@export var follow_distance: float = 350.0  # Khoảng cách giữ với player
@export var move_speed: float = 150.0  # Tốc độ di chuyển của boss

func _enter():
	# Tắt gravity và cho phép di chuyển
	obj.ignore_gravity = true
	obj.is_movable = true
	obj.velocity.x = 0
	
	# Play animation nếu có
	if obj.animated_sprite_2d and obj.animated_sprite_2d.sprite_frames.has_animation("cast"):
		obj.animated_sprite_2d.play("cast")
	
	# Lấy player
	var player = get_tree().get_first_node_in_group("player")
	if not player:
		obj.is_movable = true
		change_state(fsm.states.idle)
		return
	
	# Bắn đạn và di chuyển theo player
	for shot in range(shot_count):
		# Kiểm tra phase
		if obj.current_phase != obj.Phase.FLY:
			obj.is_movable = true
			change_state(fsm.states.idle)
			return
		
		# Di chuyển về phía player giữ khoảng cách
		await _move_towards_player(player, shot_interval)
		
		# Bắn burst đạn về phía player
		_shoot_burst_at_player(player)
	
	# Đợi 1.5 giây trước khi kết thúc skill
	await get_tree().create_timer(1.5).timeout
	
	# Kết thúc skill
	obj.is_movable = true
	obj.use_skill()

func _move_towards_player(player: Node2D, duration: float):
	"""Di chuyển boss về phía player trong khoảng thời gian duration, giữ khoảng cách follow_distance"""
	var start_time = Time.get_ticks_msec() / 1000.0
	var elapsed = 0.0
	
	while elapsed < duration:
		if not is_instance_valid(player):
			break
		
		var boss_pos = obj.global_position
		var player_pos = player.global_position
		var distance = boss_pos.distance_to(player_pos)
		
		# Tính hướng đến player
		var direction = (player_pos - boss_pos).normalized()
		
		# Nếu quá xa, di chuyển lại gần
		if distance > follow_distance + 50:
			obj.velocity = direction * move_speed
		# Nếu quá gần, lùi lại
		elif distance < follow_distance - 50:
			obj.velocity = -direction * move_speed
		# Trong khoảng hợp lý, di chuyển chậm hoặc dừng
		else:
			obj.velocity = direction * move_speed * 0.3
		
		# Flip sprite theo hướng di chuyển
		if obj.velocity.x < 0 and not obj.animated_sprite_2d.flip_h:
			obj.animated_sprite_2d.flip_h = true
		elif obj.velocity.x > 0 and obj.animated_sprite_2d.flip_h:
			obj.animated_sprite_2d.flip_h = false
		
		await get_tree().process_frame
		elapsed = (Time.get_ticks_msec() / 1000.0) - start_time
	
	obj.velocity = Vector2.ZERO

func _shoot_burst_at_player(player: Node2D):
	"""Bắn burst đạn về phía player"""
	if not is_instance_valid(player):
		return
	
	for i in range(shots_per_burst):
		if not is_instance_valid(player):
			break
		
		var boss_pos = obj.global_position
		var player_pos = player.global_position
		
		# Tính direction từ boss đến player
		var dir = (player_pos - boss_pos).normalized()
		
		# Thêm spread nhỏ cho đạn
		var spread_angle = (randf() - 0.5) * 0.2  # ±0.1 radian spread
		dir = dir.rotated(spread_angle)
		
		# Spawn meteor
		_spawn_meteor(boss_pos, dir)
		
		# Delay giữa các đạn trong burst
		if i < shots_per_burst - 1:
			await get_tree().create_timer(burst_delay).timeout

func _move_horizontally():
	# Hàm này không còn dùng nữa, giữ lại để tránh lỗi
	pass

func alert_coroutine(warnings: Array) -> void:
	# Hàm này không còn dùng nữa, giữ lại để tránh lỗi
	pass

func _spawn_star(target_pos: Vector2) -> Node2D:
	# Hàm này không còn dùng nữa, giữ lại để tránh lỗi
	return null

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
