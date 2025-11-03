class_name EnemyCharacter
extends BaseCharacter

# Raycast check wall and fall
var front_ray_cast: RayCast2D
var down_ray_cast: RayCast2D

# Raycast detect player (left / right)
var left_detect_ray: RayCast2D
var right_detect_ray: RayCast2D

# Player reference
var found_player: Player = null


func _ready() -> void:
	_init_ray_cast()
	_init_detect_player_raycast()
	_init_hurt_area()
	super._ready()


# --- Initialize raycasts for wall/fall detection
func _init_ray_cast():
	if has_node("Direction/FrontRayCast2D"):
		front_ray_cast = $Direction/FrontRayCast2D
	if has_node("Direction/DownRayCast2D"):
		down_ray_cast = $Direction/DownRayCast2D


# --- Initialize raycasts for detecting player
func _init_detect_player_raycast():
	if has_node("Direction/LeftDetectRayCast2D"):
		left_detect_ray = $Direction/LeftDetectRayCast2D
	if has_node("Direction/RightDetectRayCast2D"):
		right_detect_ray = $Direction/RightDetectRayCast2D


# --- Initialize hurt area
func _init_hurt_area():
	if has_node("Direction/HurtArea2D"):
		var hurt_area = $Direction/HurtArea2D
		hurt_area.hurt.connect(_on_hurt_area_2d_hurt)


# --- Check if touching wall
func is_touch_wall() -> bool:
	return front_ray_cast != null and front_ray_cast.is_colliding()


# --- Check if can fall
func is_can_fall() -> bool:
	return down_ray_cast != null and not down_ray_cast.is_colliding()


# --- Called every frame (or physics frame)
func _physics_process(delta: float) -> void:
	super._physics_process(delta)
	_check_player_in_sight()


# --- Check player detection via raycast
func _check_player_in_sight():
	var detected_player := _get_player_from_raycasts()
	
	if detected_player != found_player:
		if detected_player:
			found_player = detected_player
			_on_player_in_sight(found_player.global_position)
		else:
			_on_player_not_in_sight()
			found_player = null


# --- Helper: returns player if any raycast hit it
func _get_player_from_raycasts() -> Player:
	if left_detect_ray and left_detect_ray.is_colliding():
		var collider = left_detect_ray.get_collider()
		if collider is Player:
			return collider

	if right_detect_ray and right_detect_ray.is_colliding():
		var collider = right_detect_ray.get_collider()
		if collider is Player:
			return collider

	return null


# --- Called when player is in sight
func _on_player_in_sight(_player_pos: Vector2) -> void:
	print("Player detected at:", _player_pos)


# --- Called when player is not in sight
func _on_player_not_in_sight() -> void:
	print("Player lost from sight")


# --- When enemy takes damage
func _on_hurt_area_2d_hurt(_direction: Vector2, _damage: float, _elemental_type: int) -> void:
	# Tính damage dựa trên quan hệ sinh - khắc
	var modified_damage = calculate_elemental_damage(_damage, _elemental_type)
	fsm.current_state.take_damage(_direction, modified_damage)
	handle_elemental_damage(_elemental_type)

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


# --- Apply damage through FSM
func _take_damage_from_dir(_damage_dir: Vector2, _damage: float):
	fsm.current_state.take_damage(_damage_dir, _damage)
