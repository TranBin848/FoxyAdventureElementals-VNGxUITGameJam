extends AreaBase
class_name ThousandSwordsArea

# --- Configuration ---
@export_group("Sword Settings")
@export var sword_scene_path: String = "res://skills/projectiles/SwordProjectile.tscn"
@export var sword_count: int = 12
@export var spawn_interval: float = 0.05    
@export var fire_interval: float = 0.08     

@export_group("Positioning")
@export var hover_height: float = 120.0     
@export var ring_radius: float = 50.0      
@export var grave_scatter: float = 20.0     

var sword_scene: PackedScene
var active_swords: Array[SwordProjectile] = []
var current_target: Node2D = null 
var is_firing: bool = false 

func setup(skill: Skill, caster_position: Vector2, enemy: EnemyCharacter, direction: Vector2 = Vector2.RIGHT) -> void:
	# 1. Base Setup (Handles damage, elemental type, duration timer)
	super.setup(skill, caster_position, enemy, direction)
	
	# 2. Shift Position Logic
	# Move the area (the center of the ring) above the player's head
	self.global_position = caster_position + Vector2(0, -hover_height)
	
	# 3. Disable the Area's own hitbox (It's just a manager)
	_disable_hitbox()
	
	print("[ThousandSwords] Setup. Area Pos: %s" % global_position)
	
	sword_scene = load(sword_scene_path)
	if not sword_scene:
		push_error("[ThousandSwords] Failed to load projectile scene.")
		return
	
	_sequence_start()

func _physics_process(delta: float) -> void:
	if current_target and is_instance_valid(current_target) and not active_swords.is_empty():
		var target_pos = current_target.global_position
		for sword in active_swords:
			if not is_instance_valid(sword):
				continue

			# Only rotate swords that haven't launched AND aren't stuck
			if not sword.active and not sword.is_stuck:
				var dir_to_target = (target_pos - sword.global_position).normalized()
				var target_angle = dir_to_target.angle()
				sword.rotation = lerp_angle(sword.rotation, target_angle, 10 * delta)

func _sequence_start() -> void:
	active_swords.clear()
	is_firing = false
	
	# --- PHASE 1: SUMMONING (Circle formation) ---
	print("[ThousandSwords] Phase 1: Summoning...")
	var angle_step = (2.0 * PI) / sword_count
	
	for i in range(sword_count):
		if not is_instance_valid(self): return
		
		# Calculate ring position
		var angle = i * angle_step - (PI / 2) # Start from top
		var offset = Vector2(cos(angle), sin(angle)) * ring_radius
		var spawn_pos = global_position + offset
		
		# Instantiate
		var sword = sword_scene.instantiate() as SwordProjectile
		get_tree().current_scene.add_child(sword)
		
		# Setup in HOVER mode
		sword.setup_hover(spawn_pos, damage, elemental_type, duration + 2.0)
		
		# Visual Rotation: Point outward initially (Sun rays)
		sword.rotation = angle 
		
		active_swords.append(sword)
		
		# Stagger spawn
		await get_tree().create_timer(spawn_interval).timeout

	# --- PHASE 2: TARGETING (Highest Visible HP) ---
	print("[ThousandSwords] Phase 2: Finding High Value Target...")
	current_target = _find_highest_hp_enemy()
	
	if current_target:
		print("[ThousandSwords] LOCKED ON: %s" % current_target.name)
	else:
		print("[ThousandSwords] NO TARGET. Aiming at fallback.")

	# Short pause to let player see the "Lock On" rotation effect
	await get_tree().create_timer(0.4).timeout

	# --- PHASE 3: FIRING (Sword Grave Distribution) ---
	print("[ThousandSwords] Phase 3: Firing.")
	is_firing = true
	
	# Default fallback: Ground in front of player
	var fallback_pos = global_position + (Vector2.RIGHT * 300) + Vector2(0, hover_height)
	if direction.x < 0: fallback_pos = global_position + (Vector2.LEFT * 300) + Vector2(0, hover_height)
	
	for sword in active_swords:
		if not is_instance_valid(sword): continue
		
		# Dynamic Targeting: Track target even if they move
		var aim_base_pos = fallback_pos
		if is_instance_valid(current_target):
			aim_base_pos = current_target.global_position
			fallback_pos = aim_base_pos # Update fallback
			
		# DISTRIBUTION LOGIC: 
		# Pick a random point inside a circle around the target
		# 
		# We use sqrt(randf()) to ensure even spread, otherwise they clump in center
		var random_angle = randf() * 2.0 * PI
		var random_dist = sqrt(randf()) * grave_scatter
		var scatter_offset = Vector2(cos(random_angle), sin(random_angle)) * random_dist
		
		var final_impact_pos = aim_base_pos + scatter_offset
		
		# Launch
		sword.launch(final_impact_pos)
		
		await get_tree().create_timer(fire_interval).timeout

func _find_highest_hp_enemy() -> Node2D:
	var candidates = get_tree().get_nodes_in_group("enemies")
	
	# Debug 1: Are we even finding nodes?
	print("--- TARGETING DEBUG ---")
	print("Candidates in group 'enemies': %d" % candidates.size())
	
	var viewport_rect = get_viewport().get_visible_rect()
	var canvas_transform = get_canvas_transform()
	
	print("Viewport Rect: %s" % viewport_rect)
	
	var best_target: Node2D = null
	var highest_hp: float = -1.0
	
	for enemy in candidates:
		if not is_instance_valid(enemy): continue
		
		# Debug 2: Check Position Math
		var screen_pos = canvas_transform * enemy.global_position
		var is_visible = viewport_rect.has_point(screen_pos)
		
		print("Checking [%s]:" % enemy.name)
		print(" - Global Pos: %s" % enemy.global_position)
		print(" - Screen Pos: %s" % screen_pos)
		print(" - Visible?: %s" % is_visible)
		
		if not is_visible:
			continue

		# Debug 3: Check HP Logic
		var hp_val = 0.0
		if enemy.has_method("get_max_health"):
			hp_val = enemy.get_max_health()
		elif "max_health" in enemy:
			hp_val = enemy.max_health
		elif "stats" in enemy and "max_health" in enemy.stats:
			hp_val = enemy.stats.max_health
		else:
			print(" - FAILURE: Could not find HP variable.")
			continue
			
		print(" - HP Found: %s" % hp_val)
			
		if hp_val > highest_hp:
			highest_hp = hp_val
			best_target = enemy
			
	print("--- END DEBUG ---")
	return best_target
