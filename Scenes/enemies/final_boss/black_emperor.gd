class_name BlackEmperor
extends EnemyCharacter

signal phase_transition_started

@onready var hit_box: CollisionShape2D = $Direction/HitArea2D/CollisionShape2D
@onready var hurt_box: CollisionShape2D = $Direction/HurtArea2D/CollisionShape2D2
@onready var collision: CollisionShape2D = $CollisionShape2D

@onready var animated_sprite_2d: AnimatedSprite2D = $Direction/AnimatedSprite2D
@onready var health_bar: ProgressBar = $UI/Control/ProgressBar
@onready var label: Label = $Label

@export var atk_range: float = 200
@export var spin_velocity = 300
@export var spawner_scene: PackedScene  # Scene của spawner
@export var enemies_to_spawn: Array[PackedScene]  # Các enemy để spawner spawn
@export var spawner_radius: float = 120.0  # Bán kính ngôi sao
@export var spawner_health: int = 5  # Máu của mỗi spawner (số lần spawn)

var is_stunned: bool = false
var boss_zone: Area2D = null
var is_fighting: bool = false
var fly_target_y: float = 0.0  # Độ cao bay cố định khi ở phase FLY
var ground_y: float = 0.0  # Độ cao mặt đất ban đầu
var original_x: float = 0.0  # Vị trí x ban đầu để di chuyển qua lại
var spawned_spawners: Array = []  # Lưu các spawner đã tạo

enum Phase {
	FLY,
	CUTSCENE
}

var skills_phase_1 = {
	0: "flylightning",
	1: "meteorrain",
	2: "rainbullets"
}

# Phase 2: cutscene transition (không có skill, chỉ cutscene)
var skills_phase_2 = {}

var current_phase: Phase = Phase.FLY

var skill_cd_timer = 0
var cur_skill = 0

func _ready() -> void:
	super._ready()
	fsm = FSM.new(self, $States, $States/Idle)
	ground_y = global_position.y  # Lưu độ cao mặt đất
	fly_target_y = global_position.y - 200 #độ cao bay
	original_x = global_position.x  # Lưu vị trí x ban đầu
	
	add_to_group("enemies")

func _physics_process(delta: float) -> void:
	super._physics_process(delta)
	if skill_cd_timer > 0:
		skill_cd_timer -= delta
	label.text = str(fsm.current_state)
	
func use_skill() -> void:
	
	var skill_dict

	match current_phase:
		Phase.FLY:
			skill_dict = skills_phase_1
		Phase.CUTSCENE:
			skill_dict = skills_phase_2

	if skill_dict.is_empty():
		return
	
	var skill = skill_dict[cur_skill]
	print("Skill: ", skill)
	fsm.change_state(fsm.states[skill])

	cur_skill = (cur_skill + 1) % skill_dict.size()


func take_damage(damage: int) -> void:
	super.take_damage(damage)
	
	AudioManager.play_sound("boss_hurt")
	
	flash_corountine()
	var health_percent = (float(health) / max_health) * 100
	health_bar.value = health_percent
	
	# Phase FLY -> Phase CUTSCENE: khi máu <= 33.33%
	if health_percent <= 33.33 and current_phase == Phase.FLY:
		enter_phase_cutscene()

func enter_phase_cutscene() -> void:
	current_phase = Phase.CUTSCENE
	cur_skill = 0
	
	print("Entering Phase CUTSCENE")
	
	# Emit signal để AnimatedBg bắt đầu cutscene sequence
	phase_transition_started.emit()
	
	# Chuyển sang state cutscene1
	if fsm.states.has("cutscene1"):
		fsm.change_state(fsm.states.cutscene1)
	else:
		print("Error: cutscene1 state not found!")

func _spawn_star_spawners(active: bool = true) -> void:
	if spawner_scene == null:
		print("Error: spawner_scene not assigned in BlackEmperor!")
		return
	
	# Xóa spawner cũ nếu có
	for s in spawned_spawners:
		if is_instance_valid(s):
			s.queue_free()
	spawned_spawners.clear()
	
	# 5 hệ nguyên tố
	var element_types = [
		ElementsEnum.Elements.METAL,
		ElementsEnum.Elements.WOOD, 
		ElementsEnum.Elements.WATER,
		ElementsEnum.Elements.FIRE,
		ElementsEnum.Elements.EARTH
	]
	
	# Tâm của boss zone theo trục x, y cố định ở trên cao
	var center_x = global_position.x
	var center_y = ground_y - 200  # Y cố định, cao hơn mặt đất 100 pixel
	
	# Nếu có boss_zone, lấy tâm x của boss_zone
	if boss_zone:
		var zone_center = boss_zone.global_position
		center_x = zone_center.x
	
	var center = Vector2(center_x, center_y)
	
	# Góc bắt đầu từ đỉnh trên (-90 độ)
	var start_angle = -PI / 2
	
	for i in range(5):
		var spawner = spawner_scene.instantiate()
		
		# Tính góc cho đỉnh thứ i của ngôi sao (ngũ giác)
		var angle = start_angle + (i * 2 * PI / 5)
		
		# Tính vị trí theo tọa độ cực
		var offset_x = cos(angle) * spawner_radius
		var offset_y = sin(angle) * spawner_radius
		
		spawner.global_position = Vector2(center.x + offset_x, center.y + offset_y)
		
		# Set elemental type
		if "elemental_type" in spawner:
			spawner.elemental_type = element_types[i]
		
		# Set enemies để spawn
		if enemies_to_spawn.size() > 0 and "enemy_to_spawn" in spawner:
			spawner.enemy_to_spawn = enemies_to_spawn
		
		# Set máu spawner (spawn liên tục nhiều con)
		if "max_health" in spawner:
			spawner.max_health = spawner_health
			spawner.health = spawner_health
		
		# Set spawn_interval chậm hơn nhiều
		if "spawn_interval" in spawner:
			spawner.spawn_interval = 8.0  # Spawn chậm hơn (8 giây)
		
		# Nếu chưa active, pause spawner
		if not active and "is_paused" in spawner:
			spawner.is_paused = true
		elif not active:
			spawner.set_process(false)
			spawner.set_physics_process(false)
		
		# Thêm vào scene
		var enemies_container = GameManager.current_stage.find_child("Enemies")
		if enemies_container:
			enemies_container.add_child(spawner)
		else:
			get_parent().add_child(spawner)
		
		spawned_spawners.append(spawner)
	
	print("Spawned 5 spawners in star shape around boss")

func _spawn_star_spawners_with_fade(active: bool = true) -> void:
	if spawner_scene == null:
		print("Error: spawner_scene not assigned in BlackEmperor!")
		return
	
	# Xóa spawner cũ nếu có
	for s in spawned_spawners:
		if is_instance_valid(s):
			s.queue_free()
	spawned_spawners.clear()
	
	# 5 hệ nguyên tố
	var element_types = [
		ElementsEnum.Elements.METAL,
		ElementsEnum.Elements.WOOD, 
		ElementsEnum.Elements.WATER,
		ElementsEnum.Elements.FIRE,
		ElementsEnum.Elements.EARTH
	]
	
	# Tâm của boss zone theo trục x, y cố định ở trên cao
	var center_x = global_position.x
	var center_y = ground_y - 200  # Y cố định, cao hơn mặt đất
	
	# Nếu có boss_zone, lấy tâm x của boss_zone
	if boss_zone:
		var zone_center = boss_zone.global_position
		center_x = zone_center.x
	
	var center = Vector2(center_x, center_y)
	
	# Góc bắt đầu từ đỉnh trên (-90 độ)
	var start_angle = -PI / 2
	
	for i in range(5):
		var spawner = spawner_scene.instantiate()
		
		# Tính góc cho đỉnh thứ i của ngôi sao (ngũ giác)
		var angle = start_angle + (i * 2 * PI / 5)
		
		# Tính vị trí theo tọa độ cực
		var offset_x = cos(angle) * spawner_radius
		var offset_y = sin(angle) * spawner_radius
		
		spawner.global_position = Vector2(center.x + offset_x, center.y + offset_y)
		
		# Set elemental type
		if "elemental_type" in spawner:
			spawner.elemental_type = element_types[i]
		
		# Set enemies để spawn
		if enemies_to_spawn.size() > 0 and "enemy_to_spawn" in spawner:
			spawner.enemy_to_spawn = enemies_to_spawn
		
		# Set máu spawner (spawn liên tục nhiều con)
		if "max_health" in spawner:
			spawner.max_health = spawner_health
			spawner.health = spawner_health
		
		# Set spawn_interval chậm hơn nhiều
		if "spawn_interval" in spawner:
			spawner.spawn_interval = 8.0  # Spawn chậm hơn (8 giây)
		
		# Nếu chưa active, pause spawner
		if not active and "is_paused" in spawner:
			spawner.is_paused = true
		elif not active:
			spawner.set_process(false)
			spawner.set_physics_process(false)
		
		# === HIỆU ỨNG FADE IN ===
		# Set alpha ban đầu = 0 (trong suốt hoàn toàn)
		spawner.modulate = Color(1, 1, 1, 0)
		
		# Thêm vào scene
		var enemies_container = GameManager.current_stage.find_child("Enemies")
		if enemies_container:
			enemies_container.add_child(spawner)
		else:
			get_parent().add_child(spawner)
		
		spawned_spawners.append(spawner)
		
		# Tween fade in với delay giữa các spawner
		var fade_tween = create_tween()
		fade_tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
		fade_tween.tween_property(spawner, "modulate", Color(1, 1, 1, 1), 0.5).set_delay(i * 0.1)
	
	print("Spawned 5 spawners with fade effect in star shape around boss")

func _activate_spawners() -> void:
	# Kích hoạt tất cả spawner sau khi boss hạ cánh
	for spawner in spawned_spawners:
		if is_instance_valid(spawner):
			if "is_paused" in spawner:
				spawner.is_paused = false
			spawner.set_process(true)
			spawner.set_physics_process(true)
	print("Spawners activated!")

func _land_on_ground() -> void:
	# Di chuyển boss từ vị trí bay xuống mặt đất CHẬM
	var land_speed = 80.0  # Tốc độ hạ cánh chậm
	
	while global_position.y < ground_y:
		var delta = get_physics_process_delta_time()
		global_position.y += land_speed * delta
		
		# Đảm bảo không vượt quá mặt đất
		if global_position.y >= ground_y:
			global_position.y = ground_y
			break
		
		await get_tree().process_frame
	
	# Đảm bảo boss ở đúng vị trí mặt đất
	global_position.y = ground_y
	
	# Đợi thêm một chút sau khi hạ cánh - boss đứng im
	await get_tree().create_timer(1.0).timeout
	
func flash_corountine() -> void:
	animated_sprite_2d.modulate = Color(20, 20, 20)
	await get_tree().create_timer(0.3).timeout
	animated_sprite_2d.modulate = Color.WHITE  # go back to normal	

func start_fight() -> void:
	health_bar.show()
	is_fighting = true

func handle_dead() -> void:
	pass
	
func is_at_camera_edge(margin: float = 15.0) -> bool:
	var cam := get_viewport().get_camera_2d()
	if cam == null:
		return false

	var viewport := get_viewport()
	var screen_size := viewport.get_visible_rect().size

	# Convert screen coords → world coords
	var canvas_xform := viewport.get_canvas_transform().affine_inverse()

	var left_edge  = canvas_xform * Vector2(0, screen_size.y * 0.5)
	var right_edge = canvas_xform * Vector2(screen_size.x, screen_size.y * 0.5)

	var x := global_position.x
	#print("camera edges:", left_edge, right_edge, " obj:", x)
	return (x <= left_edge.x + margin and velocity.x < 0) or (x >= right_edge.x - margin and velocity.x > 0) 
