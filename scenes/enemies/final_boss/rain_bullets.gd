extends BlackEmperorState

@export var water_bullet_scene: PackedScene  # Scene của đạn nước
@export var bullet_count: int = 20  # Số lượng đạn trong vòng tròn
@export var ring_radius: float = 100.0  # Bán kính vòng tròn
@export var spawn_interval: float = 0.05  # Delay giữa mỗi đạn spawn
@export var fire_interval: float = 0.08  # Delay giữa mỗi đạn bắn
@export var bullet_speed: float = 400.0  # Tốc độ đạn
@export var bullet_damage: int = 10  # Damage của đạn

var active_bullets: Array = []
var player_target: Node2D = null

func _enter():
	# Boss bay lên (hoặc giữ nguyên độ cao nếu đang bay)
	var start_pos = obj.global_position
	var target_fly_pos = Vector2(start_pos.x, obj.fly_target_y)
	
	# Tắt gravity và di chuyển
	obj.ignore_gravity = true
	obj.is_movable = false
	obj.velocity.x = 0
	
	# Play animation nếu có
	if obj.animated_sprite_2d and obj.animated_sprite_2d.sprite_frames.has_animation("cast"):
		obj.animated_sprite_2d.play("cast")
	
	# Bay lên độ cao nếu chưa đạt độ cao đó
	if start_pos.y > obj.fly_target_y:
		var tween = get_tree().create_tween()
		tween.tween_property(obj, "global_position", target_fly_pos, 0.8).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		await tween.finished
	
	# Tìm player
	player_target = _find_player()
	
	# Bắt đầu spawn và bắn đạn
	await _spawn_and_fire_bullets()
	
	# Khôi phục trạng thái
	obj.is_movable = true
	
	# Đợi 3 giây trước khi chuyển sang skill tiếp theo
	await get_tree().create_timer(3.0).timeout
	
	# Chuyển sang skill tiếp theo
	obj.use_skill()

func _spawn_and_fire_bullets():
	active_bullets.clear()
	var boss_pos = obj.global_position
	
	# --- PHASE 1: SPAWN BULLETS IN CIRCLE ---
	var angle_step = (2.0 * PI) / bullet_count
	
	for i in range(bullet_count):
		if not is_instance_valid(self):
			return
		
		var angle = i * angle_step
		var offset = Vector2(cos(angle), sin(angle)) * ring_radius
		var spawn_pos = boss_pos + offset
		
		# Spawn đạn
		if water_bullet_scene:
			var bullet = water_bullet_scene.instantiate()
			get_tree().current_scene.add_child(bullet)
			
			# Setup bullet với vị trí, damage, element và duration
			if bullet.has_method("setup_hover"):
				bullet.setup_hover(spawn_pos, bullet_damage, ElementsEnum.Elements.WATER, 5.0)
			
			# Set rotation ban đầu theo góc vòng tròn
			bullet.rotation = angle
			
			active_bullets.append(bullet)
		
		await get_tree().create_timer(spawn_interval).timeout
	
	# --- PHASE 2: AIM AT PLAYER ---
	await get_tree().create_timer(0.5).timeout
	
	# Cập nhật vị trí player
	player_target = _find_player()
	
	print(player_target)
	
	# --- PHASE 3: FIRE BULLETS ---
	for bullet in active_bullets:
		if not is_instance_valid(bullet):
			continue
		
		# Tính vị trí mục tiêu
		var target_pos = player_target.global_position if is_instance_valid(player_target) else boss_pos + Vector2(0, 200)
		
		# Launch bullet về phía target position
		if bullet.has_method("launch"):
			bullet.launch(target_pos)
		
		await get_tree().create_timer(fire_interval).timeout

func _find_player() -> Node2D:
	# Tìm node có tên "player" trong scene
	return get_tree().current_scene.find_child("Player", true, false)
