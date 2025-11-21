class_name Player
extends BaseCharacter
@onready var camera_2d: Camera2D = $Camera2D

@export var invulnerable_duration: float = 2
var is_invulnerable: bool = false
var invulnerable_timer: float = 0
const FLICKER_INTERVAL := 0.1
var flicker_timer := 0.0

@export var has_blade: bool = false
var blade_hit_area: Area2D
@export var blade_throw_speed: float = 300
@export var skill_throw_speed: float = 200

@onready var blade_factory: Node2DFactory = $Direction/BladeFactory
@onready var jump_fx_factory: Node2DFactory = $Direction/JumpFXFactory
@onready var skill_factory: Node2DFactory = $Direction/SkillFactory

@export var push_strength = 100.0

@onready var normal_sprite: AnimatedSprite2D = $Direction/AnimatedSprite2D
@onready var blade_sprite: AnimatedSprite2D = $Direction/BladeAnimatedSprite2D
@onready var silhouette_normal_sprite: AnimatedSprite2D = $Direction/SilhouetteSprite2D
@onready var silhouette_blade_sprite: AnimatedSprite2D = $Direction/SilhouetteBladeAnimatedSprite2D

signal health_changed

var _targets_in_range: Array[Node2D] = []

func _ready() -> void:
	super._ready()
	extra_sprites.append(silhouette_normal_sprite)
	silhouette_blade_sprite.hide()
	fsm = FSM.new(self, $States, $States/Idle)
	add_to_group("player")
	GameManager.player = self	
	if has_blade:
		collected_blade()
	
	camera_2d.make_current()

# ================================================================
# === SKILL SYSTEM ===============================================
# ================================================================

func cast_spell(skill: Skill) -> bool:
	if not skill:
		return false

	# Gọi animation cast spell
	#print("Casting skill: %s (%s)" % [skill.name, skill.element])

	# Xử lý theo loại skill
	match skill.type:
		"single_shot":
			_single_shot(skill)
			return true
		"multi_shot":
			_multi_shot(skill, 2, 0.3)
			return true
		"radial":
			_radial(skill, 18)
			return true
		"area": 
			cast_skill(skill.animation_name)
			# Kiểm tra mục tiêu CHỈ cho skill dạng area
			if has_valid_target_in_range():
				var target = get_closest_target()
				if is_instance_valid(target):
					# 2. Lấy vị trí mục tiêu
					var target_pos = target.global_position
					
					# 3. Gọi hàm triệu hồi, truyền cả skill, vị trí VÀ đối tượng target
					_area_shot(skill as Skill, target_pos, target)
					return true
			else:
				print("⚠️ Không có kẻ địch trong phạm vi để dùng skill dạng Area.")
				# Tùy chọn: Đặt cooldown = 0 nếu không có mục tiêu để người chơi không bị phạt.
				# Ví dụ: skill_timer.stop()
				return false
		"buff": # ⬅️ THÊM LOGIC CHO BUFF SKILL VÀO ĐÂY
			cast_skill(skill.animation_name)
			_apply_buff(skill)
			return true # Kỹ năng Buff lên bản thân luôn thành công
		_:
			print("Unknown skill type: %s" % skill.type)
			return false
	return true

# ====== SINGLE SHOT ======
func _single_shot(skill: Skill) -> void:
	var dir := Vector2.RIGHT if direction == 1 else Vector2.LEFT
	# Đổi sang state cast
	cast_skill(skill.animation_name)
	var projectile = _spawn_projectile(skill, dir)
	if projectile:
		# projectile.setup đã gọi animation; thêm gọi play nếu muốn override
		pass

# ====== MULTI SHOT ======
func _multi_shot(skill: Skill, count: int, delay: float) -> void:
	for i in range(count):
		_single_shot(skill)
		# Hàm sẽ tạm dừng tại đây và chờ timer hết thời gian
		await get_tree().create_timer(delay).timeout

# ====== ANGLED SHOT cho radial ======
func _angled_shot(angle: float, i: int, skill: Skill) -> void:
	var dir = Vector2(cos(angle), sin(angle)).normalized()
	var projectile = _spawn_projectile(skill, dir)
	if projectile:
		# ví dụ đổi animation theo index nếu muốn
		if i % 2 == 0:
			projectile.play("Fire")
		elif i % 2 == 1:
			projectile.play("WaterBlast")

# ====== RADIAL (xung quanh) ======
func _radial(skill: Skill, count: int) -> void:
	for i in range(count):
		var angle = (float(i) / count) * 2.0 * PI
		_angled_shot(angle, i, skill)

# ====== TẠO PROJECTILE ======
# bây giờ nhận thêm dir vector và gọi setup()
func _spawn_projectile(skill: Skill, dir: Vector2) -> Area2D:
	# Nếu skill.projectile_scene là PackedScene: instantiate trực tiếp
	var proj_node: Node = null
	if skill.projectile_scene:
		proj_node = skill.projectile_scene.instantiate()
	else:
		# fallback dùng factory (nếu bệ hạ vẫn muốn dùng skill_factory)
		proj_node = skill_factory.create() if skill_factory else null

	if not proj_node:
		return null

	var proj = proj_node as Area2D
	if proj == null:
		return null

	# nếu có method setup, gọi nó; nếu không, set thẳng thuộc tính
	if proj.has_method("setup"):
		proj.setup(skill, dir)
	else:
		# fallback: gán thủ công
		if proj.has_variable("speed"):
			proj.speed = skill.speed
		if proj.has_variable("damage"):
			proj.damage = skill.damage
		if proj.has_variable("direction"):
			proj.direction = dir

	proj.global_position = skill_factory.global_position
	
	# add to scene tree
	get_tree().current_scene.add_child(proj)

	return proj

# ====== AREA SHOT (Triệu hồi vùng) ======
# NHẬN THÊM THAM SỐ target_position: Vector2
func _area_shot(skill: Skill, target_position: Vector2, target_enemy: Node2D) -> void:	
	if not skill.area_scene:
		print("Area skill %s missing area_scene!" % skill.name)
		return
		
	var area_node: Node = skill.area_scene.instantiate()
	if not area_node:
		return

	var area_effect = area_node as AreaBase
	if area_effect == null:
		return

	if area_effect.has_method("setup"):
		# Vùng lửa sẽ được tạo tại VỊ TRÍ KẺ ĐỊCH GẦN NHẤT
		area_effect.setup(skill, target_position, target_enemy)
	else:
		pass

	get_tree().current_scene.add_child(area_effect)

# ====== BUFF APPLICATION ======
var active_buff_node: Area2D = null
func _apply_buff(skill: Skill) -> void: 
	cast_skill(skill.animation_name)
	
	# Nếu đang có buff, hủy buff cũ trước khi áp dụng buff mới (tùy chọn)
	if is_instance_valid(active_buff_node):
		active_buff_node.queue_free()
		active_buff_node = null

	# 1. TRIỆU HỒI BUFF NODE (chỉ khi skill có packed scene)
	if skill.projectile_scene: # Giả sử bạn dùng projectile_scene để chứa BuffBase
		var buff_node = skill.projectile_scene.instantiate()
		if buff_node:
			active_buff_node = buff_node as BuffBase
			
			# Thiết lập Buff và truyền chính Player (self) vào làm caster
			active_buff_node.setup(skill, self) 
			
			# Thêm vào Scene Tree
			get_tree().current_scene.add_child(active_buff_node)
			
			# Đặt vị trí ban đầu
			active_buff_node.global_position = self.global_position

	# 2. XỬ LÝ LƯU THÔNG SỐ VÀ CÁC LOẠI BUFF CỤ THỂ (Speed, Heal, v.v.)
	match skill.type: # Bạn nên dùng skill.type thay vì skill.buff_type nếu không định nghĩa buff_type trong base Skill
		"buff":
			# Kiểm tra cụ thể xem đây là loại buff nào (dựa trên class_name)
			if skill is HealOverTime:
				var heal_skill = skill as HealOverTime
				_apply_heal_over_time(heal_skill.heal_per_tick, heal_skill.duration, heal_skill.tick_interval)
			#elif skill is SpeedBoostSkill: # Ví dụ: nếu bạn đã tạo SpeedBoostSkill
				 #_apply_speed_buff(skill.buff_value, skill.duration)
			#else:
				 #print("Unknown buff type class.")
		# ... (các loại khác nếu cần)
		_:
			print("Unknown skill type: %s" % skill.type)
	
	# 3. CHỜ HẾT DURATION (Lấy duration từ Skill)
	await get_tree().create_timer(skill.duration).timeout
	
	# 4. LOẠI BỎ BUFF (Khôi phục các thuộc tính đã thay đổi)
	# ... (Logic khôi phục tốc độ, vv) ...
	
	# 5. HỦY NODE BUFF HÀO QUANG
	if is_instance_valid(active_buff_node):
		active_buff_node.queue_free()
		active_buff_node = null

	print("❌ Buff: Hết hạn.")

# ====== HEAL OVER TIME LOGIC ======
func _apply_heal_over_time(heal_amount: float, duration: float, interval: float) -> void:
	# Tính toán tổng số lần hồi máu (ticks)
	var total_ticks: int = floor(duration / interval)
	
	print("✨ Hồi máu: Bắt đầu hồi %s HP mỗi %s giây, tổng %s lần." % [heal_amount, interval, total_ticks])
	
	for i in range(total_ticks):
		# Đảm bảo người chơi còn sống trước khi hồi máu
		if health <= 0: 
			break
			
		# Hồi máu: Giới hạn không vượt quá max_health
		health = min(health + heal_amount, max_health)
		
		health_changed.emit() # 🎯 Rất quan trọng: Phát tín hiệu cập nhật UI Health Bar
		
		# Chờ khoảng thời gian giữa các lần tick
		await get_tree().create_timer(interval).timeout
	
	print("✅ Buff Hồi máu: Hết hạn.")

# ================================================================
# === END SKILL SYSTEM ===========================================
# ================================================================

func _physics_process(delta: float) -> void:
	super._physics_process(delta)
	
	handle_invulnerable(delta)
		
	for i in get_slide_collision_count():
		var c = get_slide_collision(i)
		var body = c.get_collider()
		
		if body is RigidBody2D:
			var normal = -c.get_normal()
			body.apply_central_impulse(normal * push_strength)
			
func handle_invulnerable(delta) -> void:
	if (invulnerable_timer > 0):
		invulnerable_timer -= delta
	else:
		is_invulnerable = false
	if is_invulnerable:
		invulnerable_flicker(delta)
	else:
		animated_sprite.modulate.a = 1

func invulnerable_flicker(delta) -> void:
	flicker_timer += delta
	if flicker_timer >= FLICKER_INTERVAL:
		flicker_timer = 0.0
		animated_sprite.modulate.a = 1/(animated_sprite.modulate.a/(0.4*0.7))

func can_attack() -> bool:
	return has_blade

func collected_blade() -> void:
	has_blade = true
	set_animated_sprite(blade_sprite) # Sprite chính: cầm kiếm
	
	# Quản lý sprite silhouette:
	# 1. Ẩn sprite silhouette CŨ
	if extra_sprites.size() > 0 and extra_sprites[0] != null:
		extra_sprites[0].hide()
		extra_sprites.clear()
	# 2. Thêm sprite silhouette MỚI (cầm kiếm) và hiện nó
	extra_sprites.append(silhouette_blade_sprite)
	silhouette_blade_sprite.show()

func throw_blade() -> void:
	var blade = blade_factory.create() as RigidBody2D
	var throw_velocity := Vector2(blade_throw_speed * direction, 0.0)
	blade.direction = direction
	blade.apply_impulse(throw_velocity)
	throwed_blade()

func cast_skill(skill_name: String) -> void:
	if fsm.current_state != fsm.states.castspell:
		fsm.change_state(fsm.states.castspell)

func throwed_blade() -> void:
	has_blade = false
	set_animated_sprite($Direction/AnimatedSprite2D)
	
	# Quản lý sprite silhouette:
	# 1. Ẩn sprite silhouette CŨ
	if extra_sprites.size() > 0 and extra_sprites[0] != null:
		extra_sprites[0].hide()
		extra_sprites.clear()
	# 2. Thêm sprite silhouette MỚI (thường) và hiện nó
	extra_sprites.append(silhouette_normal_sprite)
	silhouette_normal_sprite.show()

func set_invulnerable() -> void:
	is_invulnerable = true
	invulnerable_timer = invulnerable_duration

func is_char_invulnerable() -> bool:
	return is_invulnerable

func jump() -> void:
	super.jump()
	jump_fx_factory.create() as Node2D

func _on_hurt_area_2d_hurt(_direction: Vector2, _damage: float, _elemental_type: int) -> void:
	# Tính damage dựa trên quan hệ sinh - khắc
	var modified_damage = calculate_elemental_damage(_damage, _elemental_type)
	fsm.current_state.take_damage(_direction, modified_damage)
	handle_elemental_damage(_elemental_type)
	health_changed.emit()

func save_state() -> Dictionary:
	return {
		"position": [global_position.x, global_position.y],
		"health": health,
		"has_blade": has_blade
	}

func load_state(data: Dictionary) -> void:
	"""Load player state from checkpoint data"""
	if data.has("position"):
		var pos_array = data["position"]
		global_position = Vector2(pos_array[0], pos_array[1])
	
	if data.has("health"):
		health = clamp(data["health"], 0, max_health)
	
	if data.has("has_blade"):
		has_blade = data["has_blade"]
		if has_blade:
			normal_sprite.hide()
			collected_blade() 

func calculate_elemental_damage(base_damage: float, attacker_element: int) -> float:
	# Nếu tấn công không có nguyên tố, dùng damage gốc
	if attacker_element == 0:
		return base_damage
	
	# Định nghĩa quan hệ khắc (lợi thế)
	# Fire (1) > Earth (2), Earth (2) > Water (3), Water (3) > Fire (1)
	var advantage_table = {
		1: [2],  # Fire khắc Earth
		2: [3],  # Earth khắc Water
		3: [1]   # Water khắc Fire
	}
	
	# Định nghĩa quan hệ sinh (bị khắc)
	var weakness_table = {
		1: [3],  # Fire bị Water khắc
		2: [1],  # Earth bị Fire khắc
		3: [2]   # Water bị Earth khắc
	}
	
	# Kiểm tra lợi thế (tấn công khắc phòng thủ)
	if attacker_element in advantage_table and health in advantage_table[attacker_element]:
		#print("True")
		return base_damage * 1.25  # +25% damage
	
	# Kiểm tra bất lợi (tấn công bị khắc bởi phòng thủ)
	if attacker_element in weakness_table and elemental_type in weakness_table[attacker_element]:
		return base_damage * 0.75  # -25% damage
	
	return base_damage

func handle_elemental_damage(elemental_type: int) -> void:
	match elemental_type:
		0:  # None
			pass
		1:  # Fire - burn status
			apply_fire_effect()
		2:  # Earth - slow status
			apply_earth_effect()
		3:  # Water - freeze status
			apply_water_effect()

func apply_fire_effect() -> void:
	# Có thể thêm hiệu ứng lửa (burn status, animation, etc)
	pass

func apply_earth_effect() -> void:
	# Có thể thêm hiệu ứng đất (slow, knockback, etc)
	pass

func apply_water_effect() -> void:
	# Có thể thêm hiệu ứng nước (freeze, slow, etc)
	pass

func _update_elemental_palette() -> void:
	var shader_material = ShaderMaterial.new()
	shader_material.shader = load("res://Scenes/player/player_glowing.gdshader")
	animated_sprite.material = shader_material
	
	var shader_mat = animated_sprite.material as ShaderMaterial
	shader_mat.set_shader_parameter("elemental_type", elemental_type)
	shader_mat.set_shader_parameter("glow_intensity", 1.5)

# ================================================================
# === DETECTION AREA SIGNALS =====================================
# ================================================================

# Hàm được gọi khi một Node2D đi vào DetectionArea2D
func _on_detection_area_2d_body_entered(body: Node2D):
	# Giả sử mọi kẻ địch đều có group "enemies"
	# Hoặc sử dụng class_name "EnemyCharacter" nếu bạn đã định nghĩa nó
	if body.is_in_group("enemies") or body is EnemyCharacter:
		if not _targets_in_range.has(body):
			_targets_in_range.append(body)
			# print("Enemy entered range: ", body.name)

# Hàm được gọi khi một Node2D đi ra khỏi DetectionArea2D
func _on_detection_area_2d_body_exited(body: Node2D):
	if _targets_in_range.has(body):
		_targets_in_range.erase(body)
		# print("Enemy exited range: ", body.name)

# --- NEW HELPER FUNCTION ---
# Hàm kiểm tra xem có mục tiêu hợp lệ nào trong phạm vi không
func has_valid_target_in_range() -> bool:
	# Lọc qua danh sách để đảm bảo các Node vẫn hợp lệ (chưa bị xóa)
	_targets_in_range = _targets_in_range.filter(func(target): return is_instance_valid(target))
	
	return not _targets_in_range.is_empty()

# Hàm lấy vị trí mục tiêu gần nhất để định vị Area Skill
func get_closest_target() -> Node2D:
	# Lọc qua danh sách để đảm bảo các Node vẫn hợp lệ (chưa bị xóa)
	_targets_in_range = _targets_in_range.filter(func(target): return is_instance_valid(target))
	
	if _targets_in_range.is_empty():
		return null
	
	var closest_target: Node2D = null
	var min_distance_sq: float = INF
	
	for target in _targets_in_range:
		var distance_sq = global_position.distance_squared_to(target.global_position)
		if distance_sq < min_distance_sq:
			min_distance_sq = distance_sq
			closest_target = target
			
	return closest_target

# ================================================================
# === END DETECTION AREA SIGNALS =================================
# ================================================================
