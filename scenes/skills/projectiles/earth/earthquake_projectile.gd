extends ProjectileBase
class_name EarthquakeProjectile

@export var wave_count: int = 5              # Number of projectiles in the wave
@export var spacing: float = 48.0            # Distance between wave projectiles (pixels)
@export var spawn_stagger_sec: float = 0.05  # Delay between each segment spawn for rolling effect
@export var segment_lifetime_sec: float = 3.0  # Auto-despawn segments after this duration
@export var segment_scene: PackedScene = null  # Scene for individual wave segments

var spawner: Node2D = null
var segments_spawned: int = 0
var is_hit: bool = false

func _ready() -> void:
	# Flip sprite based on direction
	if has_node("AnimatedSprite2D"):
		var sprite = get_node("AnimatedSprite2D")
		sprite.flip_h = direction.x < 0
		sprite.visible = false  # Hide main projectile, only render segments
	
	# Create invisible spawner node that travels with projectile
	spawner = Node2D.new()
	spawner.name = "EarthquakeSpawner"
	get_parent().add_child(spawner)
	spawner.global_position = global_position
	
	# Start spawning wave segments
	_spawn_wave_continuously()

func _physics_process(delta: float) -> void:
	super._physics_process(delta)
	
	# Move spawner with projectile
	if is_instance_valid(spawner):
		spawner.global_position = global_position

func _on_hit_area_2d_hitted(area: Variant) -> void:
	_trigger_end()

func _on_body_entered(body: Node2D) -> void:
	_trigger_end()

func _trigger_end() -> void:
	if is_hit:
		return
	is_hit = true
	set_physics_process(false)
	if is_instance_valid(spawner):
		spawner.queue_free()
	
	if has_node("AnimatedSprite2D"):
		var sprite = get_node("AnimatedSprite2D")

		# 2. VITAL FIX: Check if the animation is currently playing
		# If 'is_playing()' is false, it means the non-looping animation already finished.
		if not sprite.is_playing():
			_on_projectile_animation_finished() # Call cleanup immediately
			return

		# 3. If it IS still playing, then we wait for the signal
		if not sprite.animation_finished.is_connected(_on_projectile_animation_finished):
			sprite.animation_finished.connect(_on_projectile_animation_finished, CONNECT_ONE_SHOT)
	else:
		queue_free()

func _on_projectile_animation_finished() -> void:
	queue_free()

func _spawn_wave_continuously() -> void:
	while segments_spawned < wave_count and is_inside_tree():
		_spawn_segment()
		segments_spawned += 1
		if spawn_stagger_sec > 0.0 and segments_spawned < wave_count:
			await get_tree().create_timer(spawn_stagger_sec).timeout
	
	# All segments spawned - trigger end
	if not is_hit:
		_trigger_end()

func _spawn_segment() -> void:
	if not is_instance_valid(spawner):
		return
	
	var segment: Area2D = null
	if segment_scene:
		segment = segment_scene.instantiate()
	else:
		# Fallback: create simple area with sprite
		segment = Area2D.new()
		if has_node("AnimatedSprite2D"):
			var sprite = get_node("AnimatedSprite2D").duplicate()
			sprite.visible = true  # Ensure duplicated sprite is visible
			segment.add_child(sprite)
			sprite.flip_h = direction.x < 0
			sprite.play("Earthquake")
			# Despawn fallback segment when animation finishes
			sprite.animation_finished.connect(
				func(): if is_instance_valid(segment): segment.queue_free(),
				CONNECT_ONE_SHOT
			)
		if has_node("HitArea2d"):
			var hit = get_node("HitArea2d").duplicate()
			segment.add_child(hit)
	
	if segment:
		segment.global_position = spawner.global_position
		get_tree().current_scene.add_child(segment)
		
		# Set properties if segment is ProjectileBase
		if segment is ProjectileBase:
			segment.speed = 0
			segment.damage = damage
			segment.elemental_type = elemental_type
			if segment.has_node("AnimatedSprite2D"):
				var seg_sprite = segment.get_node("AnimatedSprite2D")
				seg_sprite.flip_h = direction.x < 0
				seg_sprite.play("Earthquake")
				# Despawn segment when animation finishes
				seg_sprite.animation_finished.connect(
					func(): if is_instance_valid(segment): segment.queue_free(),
					CONNECT_ONE_SHOT
				)
