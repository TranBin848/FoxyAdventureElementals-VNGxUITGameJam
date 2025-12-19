extends ProjectileBase
class_name EarthquakeProjectile

@export var wave_count: int = 5
@export var spacing: float = 48.0
@export var spawn_stagger_sec: float = 0.05
@export var segment_lifetime_sec: float = 3.0
@export var segment_scene: PackedScene = null

var segments_spawned: int = 0
var is_hit: bool = false

func _ready() -> void:
	# 1. HIDE VISUALS
	if has_node("Skill"):
		var sprite = get_node("Skill")
		sprite.flip_h = direction.x < 0
		sprite.visible = false
		
	if has_node("FX"):
		var sprite = get_node("FX")
		sprite.flip_h = direction.x < 0
		sprite.visible = false
	
	# 2. CONFIGURE COLLISION - Re-enable collision mask for terrain detection
	collision_layer = 0  # Doesn't exist on any layer
	collision_mask = 1   # Can detect terrain (adjust to your terrain layer)
	
	# Disable the HitArea for enemy damage on the main projectile
	if has_node("HitArea2d"):
		get_node("HitArea2d").monitorable = false
		get_node("HitArea2d").monitoring = false
	
	# Connect body_entered signal to detect terrain collision
	if not body_entered.is_connected(_on_terrain_collision):
		body_entered.connect(_on_terrain_collision)

	_spawn_wave_continuously()

func _physics_process(delta: float) -> void:
	super._physics_process(delta)

# Detect collision with terrain (TileMapLayer)
func _on_terrain_collision(body: Node2D) -> void:
	if body is TileMapLayer:
		# Spawn one final segment at collision point
		_spawn_segment()
		_trigger_end()

func _on_hit_area_2d_hitted(_area: Variant) -> void:
	pass 

func _on_body_entered(_body: Node2D) -> void:
	pass

func _trigger_end() -> void:
	if is_hit:
		return
	is_hit = true
	set_physics_process(false)
	queue_free()

func _spawn_wave_continuously() -> void:
	while segments_spawned < wave_count and is_inside_tree() and not is_hit:
		_spawn_segment()
		segments_spawned += 1
		
		if spawn_stagger_sec > 0.0 and segments_spawned < wave_count:
			await get_tree().create_timer(spawn_stagger_sec).timeout
	
	# Only end if we completed all segments naturally (not from collision)
	if not is_hit:
		_trigger_end()

func _spawn_segment() -> void:
	var segment: Area2D = null
	
	if segment_scene:
		segment = segment_scene.instantiate()
	else:
		segment = Area2D.new()
		
		if has_node("Skill"):
			var skill_sprite = get_node("Skill").duplicate()
			skill_sprite.visible = true
			segment.add_child(skill_sprite)
			skill_sprite.flip_h = direction.x < 0
			
		if has_node("FX"):
			var fx_sprite = get_node("FX").duplicate()
			fx_sprite.visible = true
			segment.add_child(fx_sprite)
			fx_sprite.flip_h = direction.x < 0
			
		if has_node("AnimationPlayer"):
			var anim_player = get_node("AnimationPlayer").duplicate()
			segment.add_child(anim_player)
			anim_player.play("Earthquake")
			anim_player.animation_finished.connect(
				func(_anim_name): if is_instance_valid(segment): segment.queue_free(),
				CONNECT_ONE_SHOT
			)
			
		if has_node("HitArea2d"):
			var hit = get_node("HitArea2d").duplicate()
			segment.add_child(hit)
			hit.monitorable = true
			hit.monitoring = true
	
	if segment:
		segment.global_position = global_position
		get_tree().current_scene.add_child(segment)
		
		if segment is ProjectileBase:
			segment.speed = 0
			segment.damage = damage
			segment.elemental_type = elemental_type
			segment.collision_mask = 2  # Enemies only
			segment.collision_layer = 0
			
			if segment.has_node("Skill"):
				segment.get_node("Skill").flip_h = direction.x < 0

			if segment.has_node("FX"):
				segment.get_node("FX").flip_h = direction.x < 0
			
			if segment.has_node("AnimationPlayer"):
				var seg_anim = segment.get_node("AnimationPlayer")
				seg_anim.play("Earthquake")
				seg_anim.animation_finished.connect(
					func(_anim_name): if is_instance_valid(segment): segment.queue_free(),
					CONNECT_ONE_SHOT
				)
