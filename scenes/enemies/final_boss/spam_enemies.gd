extends BlackEmperorState

@export var spawner_scene: PackedScene  # Preload spawner.tscn
@export var enemies_to_spawn: Array[PackedScene]  # Các enemy để spawn
@export var spawner_spawn_radius: float = 120.0  # Bán kính ngũ giác
@export var spawn_duration: float = 8.0  # Thời gian state này active
@export var spawner_health: int = 1  # Máu của mỗi spawner (chỉ spawn 1 lần)

var spawners: Array = []  # Lưu các spawner đã tạo
var spawn_timer: float = 0.0
var has_spawned: bool = false  # Đánh dấu đã spawn chưa

# 5 hệ nguyên tố: METAL, WOOD, WATER, FIRE, EARTH
var element_types = [
	ElementsEnum.Elements.METAL,
	ElementsEnum.Elements.WOOD, 
	ElementsEnum.Elements.WATER,
	ElementsEnum.Elements.FIRE,
	ElementsEnum.Elements.EARTH
]

func _enter() -> void:
	obj.velocity.x = 0
	obj.is_movable = false
	spawn_timer = spawn_duration
	has_spawned = false
	
	# Play animation cast/summon nếu có
	if obj.animated_sprite_2d:
		if obj.animated_sprite_2d.sprite_frames.has_animation("summon"):
			obj.animated_sprite_2d.play("summon")
		elif obj.animated_sprite_2d.sprite_frames.has_animation("cast"):
			obj.animated_sprite_2d.play("cast")
		else:
			obj.animated_sprite_2d.play("idle")
	
	# Spawn 5 spawner với 5 hệ khác nhau theo hình ngũ giác
	_spawn_all_spawners()

func _spawn_all_spawners() -> void:
	if spawner_scene == null:
		print("Error: spawner_scene not assigned!")
		return
	
	if has_spawned:
		return
	
	# Xóa spawner cũ nếu có
	_clear_spawners()
	
	# Vị trí boss (tâm ngũ giác)
	var center = obj.global_position
	
	# Tính vị trí 5 đỉnh ngũ giác
	# Góc bắt đầu từ đỉnh trên (-90 độ hoặc -PI/2)
	var start_angle = -PI / 2
	
	for i in range(element_types.size()):
		var spawner = spawner_scene.instantiate()
		
		# Tính góc cho đỉnh thứ i của ngũ giác
		# Mỗi đỉnh cách nhau 72 độ (2*PI/5)
		var angle = start_angle + (i * 2 * PI / 5)
		
		# Tính vị trí theo tọa độ cực
		var offset_x = cos(angle) * spawner_spawn_radius
		var offset_y = sin(angle) * spawner_spawn_radius
		
		spawner.global_position = Vector2(center.x + offset_x, center.y + offset_y)
		
		# Set elemental type cho spawner
		if "elemental_type" in spawner:
			spawner.elemental_type = element_types[i]
		
		# Set enemies để spawn
		if enemies_to_spawn.size() > 0 and "enemy_to_spawn" in spawner:
			spawner.enemy_to_spawn = enemies_to_spawn
		
		# Set máu spawner = 1 (chỉ spawn 1 lần)
		if "max_health" in spawner:
			spawner.max_health = spawner_health
			spawner.health = spawner_health
		
		# Thêm vào scene
		var enemies_container = GameManager.current_stage.find_child("Enemies")
		if enemies_container:
			enemies_container.add_child(spawner)
		else:
			obj.get_parent().add_child(spawner)
		
		spawners.append(spawner)
	
	has_spawned = true
	print("Spawned ", spawners.size(), " spawners in pentagon shape")

func _update(delta: float) -> void:
	spawn_timer -= delta
	
	# Kiểm tra nếu hết thời gian hoặc tất cả spawner đã chết
	var all_dead = true
	for spawner in spawners:
		if is_instance_valid(spawner) and spawner.health > 0:
			all_dead = false
			break
	
	if spawn_timer <= 0 or all_dead:
		_finish_state()

func _finish_state() -> void:
	# Không xóa spawner - để chúng tiếp tục tồn tại
	# Player có thể tiêu diệt chúng
	spawners.clear()
	
	obj.is_movable = true
	
	# Chuyển sang skill tiếp theo
	obj.use_skill()

func _clear_spawners() -> void:
	for spawner in spawners:
		if is_instance_valid(spawner):
			spawner.queue_free()
	spawners.clear()

func _exit() -> void:
	# Không clear spawners khi exit - để chúng tồn tại
	spawners.clear()
	_clear_spawners()
