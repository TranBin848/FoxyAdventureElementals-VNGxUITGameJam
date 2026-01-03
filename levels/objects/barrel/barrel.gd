extends RigidBody2D
class_name DestructibleObject

# --- COMBAT STATS ---
@export_group("Stats")
@export var max_health: float = 20
var health: float

# --- DEBRIS SETTINGS ---
@export_group("Visuals")
@export var debris_count: int = 5
@export var debris_texture: Texture2D 

# --- REWARD SETTINGS ---
@export_group("Rewards")
@export var coin_scene: PackedScene = preload("res://levels/objects/coin/coin.tscn")
@export var coin_amount: int = 3  # How many coins to drop
@export var coin_spread: float = 100.0 # How wide they fly out

func _ready() -> void:
	health = max_health

func take_damage(_direction: Vector2, _damage: float, elemental_type: int = 0) -> void:
	health -= _damage
	
	# Visual feedback (flash)
	var tween = create_tween()
	modulate = Color(10, 10, 10)
	tween.tween_property(self, "modulate", Color.WHITE, 0.1)
	
	if health <= 0:
		die(_direction)

func die(hit_direction: Vector2) -> void:
	# 1. Spawn Visual Debris (Instant)
	spawn_debris(hit_direction)
	
	# 2. Make the barrel "disappear" immediately
	hide()
	sleeping = true # Stop physics calculations
	collision_layer = 0 # Disable collision so player can't hit the invisible barrel
	collision_mask = 0
	
	# 3. Wait for the coin spawning loop to finish completely
	await spawn_coins()
	
	# 4. NOW destroy the object
	queue_free()

func spawn_coins() -> void:
	if not coin_scene: return
	
	for n in coin_amount:
		var coin_instance = coin_scene.instantiate()
		
		get_tree().current_scene.add_child(coin_instance)
		coin_instance.global_position = global_position + Vector2(0, -10)
		
		if coin_instance is RigidBody2D:
			coin_instance.apply_impulse(Vector2(
				randf_range(-coin_spread/2.0, coin_spread/2.0),
				randf_range(-150, -250)
			))
		
		await get_tree().create_timer(0.05).timeout

# --- EXISTING DEBRIS LOGIC ---
func spawn_debris(hit_direction: Vector2) -> void:
	if debris_texture == null: return 
	
	var w = debris_texture.get_width()
	var h = debris_texture.get_height()
	
	var points = PackedVector2Array()
	points.append(Vector2(0, 0))
	points.append(Vector2(w, 0))
	points.append(Vector2(w, h))
	points.append(Vector2(0, h))
	
	for i in range(debris_count):
		points.append(Vector2(randf_range(0, w), randf_range(0, h)))
	
	var triangles = Geometry2D.triangulate_delaunay(points)
	
	if triangles.is_empty(): return
		
	for i in range(0, triangles.size(), 3):
		var p1 = points[triangles[i]]
		var p2 = points[triangles[i+1]]
		var p3 = points[triangles[i+2]]
		
		_create_shard_body(hit_direction, [p1, p2, p3], w, h)

func _create_shard_body(hit_direction: Vector2, polygon_points: PackedVector2Array, tex_w: float, tex_h: float) -> void:
	var shard = RigidBody2D.new()
	
	shard.collision_layer = 0 
	shard.collision_mask = 1 # Collides with floor only
	
	var center = (polygon_points[0] + polygon_points[1] + polygon_points[2]) / 3.0
	
	var local_points = PackedVector2Array()
	for p in polygon_points:
		local_points.append(p - center)
	
	var poly_vis = Polygon2D.new()
	poly_vis.texture = debris_texture
	poly_vis.polygon = local_points
	poly_vis.uv = polygon_points 
	shard.add_child(poly_vis)
	
	var poly_col = CollisionPolygon2D.new()
	poly_col.polygon = local_points
	shard.add_child(poly_col)
	
	get_tree().current_scene.add_child(shard)
	
	var texture_offset = Vector2(tex_w / 2.0, tex_h / 2.0)
	shard.global_position = global_position - texture_offset + center
	
	var impulse_dir = hit_direction.normalized() + Vector2(randf_range(-0.5, 0.5), randf_range(-0.5, 0.5))
	shard.apply_impulse(impulse_dir * randf_range(200, 400))
	shard.angular_velocity = randf_range(-10, 10)
	
	# --- UPDATED FADE OUT LOGIC ---
	# We don't need the separate timer anymore. We use the tween's finished signal.
	
	var tween = shard.create_tween()
	# 1. Wait for 2 seconds before starting the fade
	tween.tween_interval(2.0) 
	# 2. Fade the 'alpha' component of modulate to 0 over 1.0 second
	# Using ease_in makes the fade start slowly and speed up near the end
	tween.tween_property(poly_vis, "modulate:a", 0.0, 1.0).set_ease(Tween.EASE_IN)
	# 3. When the fade is complete, delete the shard
	tween.finished.connect(shard.queue_free)
