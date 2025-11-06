class_name EnemyCharacter
extends BaseCharacter

@export var elements_color : Dictionary[ElementsEnum.Elements, Color] = {
	ElementsEnum.Elements.METAL: Color.LIGHT_GRAY,
	ElementsEnum.Elements.WOOD: Color.LIME_GREEN,
	ElementsEnum.Elements.WATER: Color.AQUA,
	ElementsEnum.Elements.FIRE: Color("ff3216"),
	ElementsEnum.Elements.EARTH: Color("d36f00")
}

# Shader that will be used for outlining the enemy based on its element
@export_file("*.gdshader") var shader_path
# Element of the enemy
@export var element: ElementsEnum.Elements
# Damage deal damage when player touch (HP)
@export var spike: float
# Detect player within this range (radius in pixel)
@export var sight: float
# Can only move within this range (radius in pixel)
@export var movement_range: float
# Enemy's jump height = jump_speed^2 / 2*gravity (pixel)
@export var jump_height: float
# Enemy's time on air = jump_speed / gravity
@export var air_time: float
# Enemy's attack speed (pixel/second)
@export var attack_speed: float

# Raycast check wall and fall
var front_ray_cast: RayCast2D
var down_ray_cast: RayCast2D

# Raycast detect player (left / right)
var left_detect_ray: RayCast2D
var right_detect_ray: RayCast2D

# Player reference
var found_player: Player = null

# Hit Area
var hit_area: HitArea2D = null

# Material to change outline
var shader_material: Material

# Enemy can only move in a range around this position
var start_position: Vector2

func _ready() -> void:
	super._ready()
	_init_ray_cast()
	_init_detect_player_raycast()
	_init_hurt_area()
	_init_hit_area()
	_init_material()
	_init_start_position()

# -- Initialize start position
func _init_start_position():
	start_position = position

# -- Initialize material
func _init_material():
	shader_material = ShaderMaterial.new()
	if shader_path == null: return
	var my_shader = load(shader_path)
	if my_shader != null:
		shader_material.shader = my_shader
	
	var outline_color = elements_color[element]
	if outline_color == null: return
	shader_material.set("shader_parameter/line_color", outline_color)
	pass


# --- Initialize element outline
func _update_element_outline():
	if animated_sprite == null: return
	if animated_sprite.material != shader_material: animated_sprite.material = shader_material
	pass


func _check_changed_animation() -> void:
	super._check_changed_animation()
	_update_element_outline()

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


# --- Initialize hit area
func _init_hit_area():
	if has_node("Direction/HitArea2D"):
		hit_area = $Direction/HitArea2D
		hit_area.damage = spike


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
func _on_hurt_area_2d_hurt(_direction: Vector2, _damage: float) -> void:
	_take_damage_from_dir(_direction, _damage)


# --- Apply damage through FSM
func _take_damage_from_dir(_damage_dir: Vector2, _damage: float):
	fsm.current_state.take_damage(_damage_dir, _damage)
	

# -- Disable collision, enemy will no longer has collision with player
func disable_collision():
	collision_layer = 0
	if hit_area != null and hit_area.has_node("CollisionShape2D"):
		hit_area.get_node("CollisionShape2D").disabled = true

# Enemy bị hút vào lốc xoáy
func enter_tornado(tornado_pos: Vector2) -> void:
	is_movable = false
	stop_move() # Dừng mọi chuyển động hiện tại
	velocity = Vector2.ZERO

	# Bắt đầu hiệu ứng "bay lên"
	var tween := get_tree().create_tween()
	tween.tween_property(self, "global_position", tornado_pos + Vector2(0, -30), 1.2).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tween.tween_callback(Callable(self, "_on_reach_tornado_top"))
	


# Callback khi chạm đỉnh lốc xoáy
func _on_reach_tornado_top() -> void:
	# Có thể lắc nhẹ, hoặc xoay tròn quanh tâm
	if animated_sprite:
		animated_sprite.rotation_degrees = 0
	print("Enemy reached top of tornado")


# Khi rời khỏi lốc xoáy (được gọi bởi tornado projectile khi kết thúc)
func exit_tornado() -> void:
	is_movable = true
	velocity = Vector2.ZERO
	# (Tuỳ chọn) rơi xuống đất sau khi thoát
	var tween := get_tree().create_tween()
	tween.tween_property(self, "global_position:y", global_position.y + 60, 0.8).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	
