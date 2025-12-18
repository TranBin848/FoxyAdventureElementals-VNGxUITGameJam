extends ProjectileBase
class_name EarthquakeProjectile

@export var wave_count: int = 5
@export var spacing: float = 48.0
@export var spawn_stagger_sec: float = 0.05
@export var segment_lifetime_sec: float = 3.0
@export var segment_scene: PackedScene = null

var segments_spawned: int = 0
var is_hit: bool = false # Kept for internal logic, though we won't set it via collision anymore

func _ready() -> void:
	# 1. HIDE VISUALS: Hide main sprite, only render segments
	if has_node("AnimatedSprite2D"):
		var sprite = get_node("AnimatedSprite2D")
		sprite.flip_h = direction.x < 0
		sprite.visible = false 
	
	# 2. DISABLE COLLISION (The Fix):
	# Turn off physics collision so the "cursor" travels through walls/enemies
	collision_layer = 0
	collision_mask = 0 
	
	# If you have a specific Hitbox/HitArea for dealing damage, disable it on the main parent
	if has_node("HitArea2d"):
		get_node("HitArea2d").monitorable = false
		get_node("HitArea2d").monitoring = false

	# Start spawning wave segments
	# (We don't need a separate Spawner node; we can just use this node's position 
	# since it moves via ProjectileBase logic)
	_spawn_wave_continuously()

func _physics_process(delta: float) -> void:
	# Continue moving using the parent class logic
	super._physics_process(delta)

# 3. OVERRIDE HIT SIGNALS:
# We override these to do NOTHING. This prevents the main projectile 
# from stopping or destroying itself when hitting something.
func _on_hit_area_2d_hitted(_area: Variant) -> void:
	pass 

func _on_body_entered(_body: Node2D) -> void:
	pass

# Only called when the WAVE is finished, not on collision
func _trigger_end() -> void:
	if is_hit:
		return
	is_hit = true
	set_physics_process(false) # Stop moving
	
	# Wait for any internal logic or just free immediately
	queue_free()

func _spawn_wave_continuously() -> void:
	while segments_spawned < wave_count and is_inside_tree():
		_spawn_segment()
		segments_spawned += 1
		
		# Wait for the stagger time before spawning the next one
		if spawn_stagger_sec > 0.0 and segments_spawned < wave_count:
			await get_tree().create_timer(spawn_stagger_sec).timeout
	
	# Once all segments are spawned, we destroy the main "cursor"
	_trigger_end()

func _spawn_segment() -> void:
	var segment: Area2D = null
	
	if segment_scene:
		segment = segment_scene.instantiate()
	else:
		# Fallback: create simple area with sprite
		segment = Area2D.new()
		
		# Duplicate Sprite
		if has_node("AnimatedSprite2D"):
			var sprite = get_node("AnimatedSprite2D").duplicate()
			sprite.visible = true # Make sure child is visible
			segment.add_child(sprite)
			sprite.flip_h = direction.x < 0
			sprite.play("Earthquake")
			sprite.animation_finished.connect(
				func(): if is_instance_valid(segment): segment.queue_free(),
				CONNECT_ONE_SHOT
			)
			
		# Duplicate Hitbox - ENABLE COLLISION HERE
		if has_node("HitArea2d"):
			var hit = get_node("HitArea2d").duplicate()
			segment.add_child(hit)
			# IMPORTANT: Re-enable collision on the child, 
			# because we disabled the original in _ready()
			hit.monitorable = true
			hit.monitoring = true
	
	if segment:
		# Spawn at current location of the main projectile
		segment.global_position = global_position
		get_tree().current_scene.add_child(segment)
		
		# Set properties if segment is ProjectileBase
		if segment is ProjectileBase:
			segment.speed = 0 # Segments stay in place
			segment.damage = damage
			segment.elemental_type = elemental_type
			
			# Ensure the segment's collision is active
			segment.collision_mask = 1 # Or whatever your enemy layer is
			segment.collision_layer = 1
			
			if segment.has_node("AnimatedSprite2D"):
				var seg_sprite = segment.get_node("AnimatedSprite2D")
				seg_sprite.flip_h = direction.x < 0
				seg_sprite.play("Earthquake")
				seg_sprite.animation_finished.connect(
					func(): if is_instance_valid(segment): segment.queue_free(),
					CONNECT_ONE_SHOT
				)
