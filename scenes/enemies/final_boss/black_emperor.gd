class_name BlackEmperor
extends EnemyCharacter

signal phase_transition_started

@onready var hit_box: CollisionShape2D = $Direction/HitArea2D/CollisionShape2D
@onready var hurt_box: CollisionShape2D = $Direction/HurtArea2D/CollisionShape2D2
@onready var collision: CollisionShape2D = $CollisionShape2D

@onready var animated_sprite_2d: AnimatedSprite2D = $Direction/AnimatedSprite2D
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
var fly_target_y: float = 0.0 
var ground_y: float = 0.0 
var original_x: float = 0.0 
var spawned_spawners: Array = [] 

signal health_percent_changed(new_value_percent: float)
signal phase_changed(new_phase_index: int)
signal fight_started
signal boss_died

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

# --- PHASE TRACKING ---
# Tracks if a specific threshold has been triggered to prevent repeating it
var phases_triggered = {
	75: false,
	50: false,
	25: false,
	0: false
}

func _ready() -> void:
	super._ready()
	fsm = FSM.new(self, $States, $States/Idle)
	ground_y = global_position.y 
	fly_target_y = global_position.y - 200 
	original_x = global_position.x 
	
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
	# print("Skill: ", skill)
	fsm.change_state(fsm.states[skill])

	cur_skill = (cur_skill + 1) % skill_dict.size()

# 1. Update take_damage to ensure we catch thresholds properly
func take_damage(damage: int) -> void:
	# If in cutscene, strictly ignore damage
	if current_phase == Phase.CUTSCENE:
		return

	# Handle 0% HP (Death Phase) explicitly
	# We anticipate the damage. If it would kill, we stop at 1 HP.
	if (health - damage) <= 0 and not phases_triggered[0]:
		health = 1 
		phases_triggered[0] = true
		health_percent_changed.emit(0.0) # Update UI to 0%
		enter_phase_cutscene("cutscene5")
		return

	super.take_damage(damage)
	
	AudioManager.play_sound("boss_hurt")
	flash_corountine()
	
	var health_percent = (float(health) / max_health) * 100
	
	# Check thresholds AFTER damage, but allow clamping inside the check
	check_phase_thresholds(health_percent)
	
	# Emit the final health percent (in case it was clamped by the threshold check)
	health_percent_changed.emit((float(health) / max_health) * 100)

# 2. Update logic to CLAMP health and disable hurtbox
func check_phase_thresholds(percent: float) -> void:
	# 25% Threshold -> Cutscene 4
	if percent <= 25.0 and not phases_triggered[25]:
		health = int(max_health * 0.25) # CLAMP HEALTH TO LIMIT
		phases_triggered[25] = true
		phases_triggered[50] = true 
		phases_triggered[75] = true
		enter_phase_cutscene("cutscene4")
		return

	# 50% Threshold -> Cutscene 2
	if percent <= 50.0 and not phases_triggered[50]:
		health = int(max_health * 0.50) # CLAMP HEALTH TO LIMIT
		phases_triggered[50] = true
		phases_triggered[75] = true
		enter_phase_cutscene("cutscene2")
		return

	# 75% Threshold -> Cutscene 1
	if percent <= 75.0 and not phases_triggered[75]:
		health = int(max_health * 0.75) # CLAMP HEALTH TO LIMIT
		phases_triggered[75] = true
		enter_phase_cutscene("cutscene1")
		return

func enter_phase_cutscene(cutscene_state_name: String) -> void:
	current_phase = Phase.CUTSCENE
	cur_skill = 0
	
	# === CRITICAL FIX: DISABLE HURTBOX ===
	# This ensures no stray bullets or lingering damage hit the boss during transition
	if hurt_box:
		hurt_box.set_deferred("disabled", true)
	
	print("Entering Phase CUTSCENE: ", cutscene_state_name)
	
	phase_transition_started.emit()
	
	if fsm.states.has(cutscene_state_name):
		fsm.change_state(fsm.states[cutscene_state_name])
	else:
		print("Error: State ", cutscene_state_name, " not found!")

# 3. Add this helper function!
# You MUST call this in your Cutscene State's _exit() function (e.g., Cutscene1.gd)
# or when the boss returns to "Idle"/"Attack" state.
func enable_hurtbox() -> void:
	if hurt_box:
		hurt_box.set_deferred("disabled", false)

# --- SPAWNER LOGIC (UNCHANGED) ---

func _spawn_star_spawners(active: bool = true) -> void:
	if spawner_scene == null:
		print("Error: spawner_scene not assigned in BlackEmperor!")
		return
	
	for s in spawned_spawners:
		if is_instance_valid(s):
			s.queue_free()
	spawned_spawners.clear()
	
	var element_types = [
		ElementsEnum.Elements.METAL,
		ElementsEnum.Elements.WOOD, 
		ElementsEnum.Elements.WATER,
		ElementsEnum.Elements.FIRE,
		ElementsEnum.Elements.EARTH
	]
	
	var center_x = global_position.x
	var center_y = ground_y - 200 
	
	if boss_zone:
		var zone_center = boss_zone.global_position
		center_x = zone_center.x
	
	var center = Vector2(center_x, center_y)
	var start_angle = -PI / 2
	
	for i in range(5):
		var spawner = spawner_scene.instantiate()
		var angle = start_angle + (i * 2 * PI / 5)
		var offset_x = cos(angle) * spawner_radius
		var offset_y = sin(angle) * spawner_radius
		
		spawner.global_position = Vector2(center.x + offset_x, center.y + offset_y)
		
		if "elemental_type" in spawner:
			spawner.elemental_type = element_types[i]
		if enemies_to_spawn.size() > 0 and "enemy_to_spawn" in spawner:
			spawner.enemy_to_spawn = enemies_to_spawn
		if "max_health" in spawner:
			spawner.max_health = spawner_health
			spawner.health = spawner_health
		if "spawn_interval" in spawner:
			spawner.spawn_interval = 8.0 
		if not active and "is_paused" in spawner:
			spawner.is_paused = true
		elif not active:
			spawner.set_process(false)
			spawner.set_physics_process(false)
		
		var enemies_container = GameManager.current_stage.find_child("Enemies")
		if enemies_container:
			enemies_container.add_child(spawner)
		else:
			get_parent().add_child(spawner)
		
		spawned_spawners.append(spawner)
	
	print("Spawned 5 spawners in star shape around boss")

func _spawn_star_spawners_with_fade(active: bool = true) -> void:
	if spawner_scene == null:
		return
	
	for s in spawned_spawners:
		if is_instance_valid(s):
			s.queue_free()
	spawned_spawners.clear()
	
	var element_types = [
		ElementsEnum.Elements.METAL,
		ElementsEnum.Elements.WOOD, 
		ElementsEnum.Elements.WATER,
		ElementsEnum.Elements.FIRE,
		ElementsEnum.Elements.EARTH
	]
	
	var center_x = global_position.x
	var center_y = ground_y - 200 
	if boss_zone:
		var zone_center = boss_zone.global_position
		center_x = zone_center.x
	
	var center = Vector2(center_x, center_y)
	var start_angle = -PI / 2
	
	for i in range(5):
		var spawner = spawner_scene.instantiate()
		var angle = start_angle + (i * 2 * PI / 5)
		var offset_x = cos(angle) * spawner_radius
		var offset_y = sin(angle) * spawner_radius
		
		spawner.global_position = Vector2(center.x + offset_x, center.y + offset_y)
		
		if "elemental_type" in spawner:
			spawner.elemental_type = element_types[i]
		if enemies_to_spawn.size() > 0 and "enemy_to_spawn" in spawner:
			spawner.enemy_to_spawn = enemies_to_spawn
		if "max_health" in spawner:
			spawner.max_health = spawner_health
			spawner.health = spawner_health
		if "spawn_interval" in spawner:
			spawner.spawn_interval = 8.0 
		if not active and "is_paused" in spawner:
			spawner.is_paused = true
		elif not active:
			spawner.set_process(false)
			spawner.set_physics_process(false)
		
		spawner.modulate = Color(1, 1, 1, 0)
		
		var enemies_container = GameManager.current_stage.find_child("Enemies")
		if enemies_container:
			enemies_container.add_child(spawner)
		else:
			get_parent().add_child(spawner)
		
		spawned_spawners.append(spawner)
		
		var fade_tween = create_tween()
		fade_tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
		fade_tween.tween_property(spawner, "modulate", Color(1, 1, 1, 1), 0.5).set_delay(i * 0.1)

func _activate_spawners() -> void:
	for spawner in spawned_spawners:
		if is_instance_valid(spawner):
			if "is_paused" in spawner:
				spawner.is_paused = false
			spawner.set_process(true)
			spawner.set_physics_process(true)
	print("Spawners activated!")

func _land_on_ground() -> void:
	var land_speed = 80.0 
	
	while global_position.y < ground_y:
		var delta = get_physics_process_delta_time()
		global_position.y += land_speed * delta
		if global_position.y >= ground_y:
			global_position.y = ground_y
			break
		await get_tree().process_frame
	
	global_position.y = ground_y
	await get_tree().create_timer(1.0).timeout
	
func flash_corountine() -> void:
	animated_sprite_2d.modulate = Color(20, 20, 20)
	await get_tree().create_timer(0.3).timeout
	animated_sprite_2d.modulate = Color.WHITE 

func start_fight() -> void:
	is_fighting = true

func start_boss_fight() -> void:
	fight_started.emit()
	phase_changed.emit(0)

func handle_dead() -> void:
	# Handled via take_damage triggering cutscene5
	pass
	
func is_at_camera_edge(margin: float = 15.0) -> bool:
	var cam := get_viewport().get_camera_2d()
	if cam == null:
		return false

	var viewport := get_viewport()
	var screen_size := viewport.get_visible_rect().size

	var canvas_xform := viewport.get_canvas_transform().affine_inverse()

	var left_edge  = canvas_xform * Vector2(0, screen_size.y * 0.5)
	var right_edge = canvas_xform * Vector2(screen_size.x, screen_size.y * 0.5)

	var x := global_position.x
	return (x <= left_edge.x + margin and velocity.x < 0) or (x >= right_edge.x - margin and velocity.x > 0)
