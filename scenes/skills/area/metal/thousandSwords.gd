# ============================================================================
# ThousandSwordsArea.gd - Direction-Aware
# ============================================================================
extends AreaBase
class_name ThousandSwordsArea

@export_group("Sword Settings")
@export var sword_scene_path: String = "res://skills/projectiles/SwordProjectile.tscn"
@export var sword_count: int = 12
@export var spawn_interval: float = 0.1 
@export var fire_interval: float = 0.08     

@export_group("Positioning")
@export var hover_height: float = 200.0     
@export var ring_radius: float = 40.0      
@export var grave_scatter: float = 20.0     

var can_rotate_swords: bool = false
var rotation_target_pos: Vector2 = Vector2.ZERO

var sword_scene: PackedScene
var active_swords: Array[SwordProjectile] = []
var current_target: Node2D = null 
var is_firing: bool = false 
var is_spawning_swords: bool = false

func setup(_skill: Skill, caster_position: Vector2, enemy: EnemyCharacter, _direction: Vector2 = Vector2.RIGHT) -> void:
	super.setup(_skill, caster_position, enemy, _direction)
	
	# Use skill's scaled damage
	self.damage = skill.get_scaled_damage()
	
	# Scale sword count, radius, height based on skill level
	var scale_factor = skill._calculate_scale()
	self.sword_count = int(sword_count * scale_factor)
	self.ring_radius = ring_radius * sqrt(scale_factor)
	self.hover_height = hover_height * scale_factor * 0.5
	self.fire_interval = fire_interval / scale_factor
	self.spawn_interval = spawn_interval / scale_factor
	
	self.global_position = caster_position + Vector2(0, -hover_height)
	_disable_hitbox()
	
	sword_scene = load(sword_scene_path)
	if not sword_scene:
		push_error("[ThousandSwords] Failed to load projectile scene.")
		return
	
	_sequence_start()

func _physics_process(delta: float) -> void:
	if not can_rotate_swords or active_swords.is_empty():
		return

	var target_pos: Vector2
	if current_target and is_instance_valid(current_target):
		target_pos = current_target.global_position
	else:
		# Use caster's direction to aim swords
		var base := global_position + Vector2(0, hover_height)
		target_pos = base + direction.normalized() * 300.0

	for sword in active_swords:
		if not is_instance_valid(sword) or sword.active or sword.is_stuck:
			continue

		var dir_to_target := (target_pos - sword.global_position).normalized()
		var target_angle := dir_to_target.angle()
		sword.rotation = lerp_angle(sword.rotation, target_angle, 10.0 * delta)

func _sequence_start() -> void:
	active_swords.clear()
	is_firing = false
	can_rotate_swords = false

	# --- AUDIO LOOP START ---
	is_spawning_swords = true
	_play_spawning_audio_loop() # Starts the sound loop coroutine
	# ------------------------

	var angle_step = (2.0 * PI) / sword_count

	for i in range(sword_count):
		if not is_instance_valid(self):
			is_spawning_swords = false # Safety stop
			return

		var angle = i * angle_step - (PI / 2)
		var offset = Vector2(cos(angle), sin(angle)) * ring_radius
		var spawn_pos = global_position + offset

		var sword = sword_scene.instantiate() as SwordProjectile
		get_tree().current_scene.add_child(sword)
		sword.setup_hover(spawn_pos, damage, elemental_type, duration + 2.0)
		sword.rotation = angle
		active_swords.append(sword)
		
		await get_tree().create_timer(spawn_interval).timeout

	# --- AUDIO LOOP STOP ---
	is_spawning_swords = false
	# -----------------------

	current_target = _find_highest_hp_enemy()
	await get_tree().create_timer(0.3).timeout
	can_rotate_swords = true

	await get_tree().create_timer(0.5).timeout
	is_firing = true
	
	# Fallback position based on caster direction
	var fallback_pos = global_position + (direction.normalized() * 300) + Vector2(0, hover_height)

	for sword in active_swords:
		if not is_instance_valid(sword):
			continue

		var aim_base_pos = fallback_pos
		if is_instance_valid(current_target):
			aim_base_pos = current_target.global_position
			fallback_pos = aim_base_pos

		var random_angle = randf() * 2.0 * PI
		var random_dist = sqrt(randf()) * grave_scatter
		var scatter_offset = Vector2(cos(random_angle), sin(random_angle)) * random_dist
		var final_impact_pos = aim_base_pos + scatter_offset

		sword.launch(final_impact_pos)
		await get_tree().create_timer(fire_interval).timeout

	can_rotate_swords = false
	
func _play_spawning_audio_loop() -> void:
	# This loop runs in parallel with the sword spawning
	while is_spawning_swords:
		# Check validity before playing to avoid errors if scene changes
		if not is_instance_valid(self):
			return
			
		AudioManager.play_sound("skill_sword_hit_enemy")
		
		# Define the "slight delay" here. 
		# We use max() to ensure it doesn't get too fast if spawn_interval is tiny.
		# 0.08s is roughly 12 sounds per second (fast but distinct).
		var audio_delay = max(spawn_interval, 0.1)
		await get_tree().create_timer(audio_delay).timeout

func _find_highest_hp_enemy() -> Node2D:
	var candidates = get_tree().get_nodes_in_group("enemies")
	var viewport_rect = get_viewport().get_visible_rect()
	var canvas_transform = get_canvas_transform()
	
	var best_target: Node2D = null
	var highest_hp: float = -1.0
	
	for enemy in candidates:
		if not is_instance_valid(enemy):
			continue
			
		if enemy is FinalBossPhaseOne:
			continue
		if enemy.fsm.current_state == enemy.fsm.states.dead:
			continue
		
		var screen_pos = canvas_transform * enemy.global_position
		if not viewport_rect.has_point(screen_pos):
			continue

		var hp_val = 0.0
		if enemy.has_method("get_max_health"):
			hp_val = enemy.get_max_health()
		elif "max_health" in enemy:
			hp_val = enemy.max_health
		elif "stats" in enemy and "max_health" in enemy.stats:
			hp_val = enemy.stats.max_health
		else:
			continue
			
		if hp_val > highest_hp:
			highest_hp = hp_val
			best_target = enemy
			
	return best_target
