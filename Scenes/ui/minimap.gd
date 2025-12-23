extends Control
class_name Minimap

# =========================================
# SETTINGS
# =========================================

@export_group("World References")
## Drag and drop all your layers here. 
## Order matters: Index 0 draws first (bottom), Index 1 draws on top.
@export var tilemap_layers: Array[TileMapLayer]
@export var player: Node2D

@export_group("Minimap Settings")
@export var minimap_size: Vector2 = Vector2(250, 250) # Horizontal default
@export var world_scale: float = 0.24
@export var rotate_with_player: bool = false
@export var circular_mask: bool = false 
## The position of the player icon (0 to 1). (0.5, 0.5) is Center.
@export var icon_offset_ratio: Vector2 = Vector2(0.5, 0.5)

@export_group("Fog of War")
@export var fow_enabled: bool = true
@export var fow_reveal_radius: float = 300.0
@export var fow_resolution: int = 2 

@export_group("Visual Style")
@export var use_textures: bool = false # Toggle this on in Inspector to see art
@export_range(0.0, 1.0) var map_opacity: float = 0.8
@export var background_color: Color = Color(0.1, 0.1, 0.15, 1.0) 
@export var border_color: Color = Color(0.8, 0.8, 0.8)
@export var default_tile_color: Color = Color(0.4, 0.4, 0.4)
## Color overlay for areas that have been explored. Use low alpha for a tint effect.
@export var discovered_tint_color: Color = Color(1.0, 1.0, 1.0, 0.2)

@export_group("Object Tracking")
@export var max_objects_to_draw: int = 200
@export var group_settings: Dictionary = {
	"enemies": {"color": Color(1.0, 0.2, 0.2), "size": 5.0, "shape": "circle"},
	"checkpoints": {"color": Color(1.0, 0.9, 0.2), "size": 4.0, "shape": "square"},
	"collectibles": {"color": Color(0.3, 0.7, 1.0), "size": 3.0, "shape": "diamond"},
	"hazards": {"color": Color(1.0, 0.5, 0.0), "size": 4.0, "shape": "triangle"}
}

# =========================================
# INTERNAL VARIABLES
# =========================================

var map_center: Vector2
var player_rotation: float = 0.0
var update_timer: float = 0.0
const UPDATE_RATE: float = 0.05 

var active_objects : Dictionary = {}
var fog_explored: Dictionary = {} 

func _ready() -> void:
	# Apply size and opacity settings
	custom_minimum_size = minimap_size
	size = minimap_size
	modulate.a = map_opacity
		
	set_process(true)

func _process(delta: float) -> void:
	update_timer += delta
	
	if player:
		map_center = player.global_position
		
		if rotate_with_player and "rotation" in player:
			player_rotation = player.rotation
		
		if fow_enabled and update_timer > 0.05:
			_reveal_fog_at_position(player.global_position)

	if update_timer >= UPDATE_RATE:
		update_timer = 0.0
		queue_redraw()

func _draw() -> void:
	# 1. Background
	if circular_mask:
		var center = minimap_size / 2
		var radius = min(minimap_size.x, minimap_size.y) / 2
		draw_circle(center, radius, background_color)
	else:
		draw_rect(Rect2(Vector2.ZERO, minimap_size), background_color)

	if not player: return

	# 2. Tiles (Multi-layer)
	if not tilemap_layers.is_empty():
		_draw_visible_tiles()

	# 3. Objects
	_draw_registered_objects()
	
	# 4. Player
	_draw_player_at_offset()
	
	# 5. Border
	if circular_mask:
		var center = minimap_size / 2
		var radius = min(minimap_size.x, minimap_size.y) / 2
		draw_arc(center, radius, 0, TAU, 64, border_color, 2.0, true)
	else:
		draw_rect(Rect2(Vector2.ZERO, minimap_size), border_color, false, 2.0)

# =========================================
# DRAWING HELPERS
# =========================================

func _draw_player_at_offset() -> void:
	var screen_pos = minimap_size * icon_offset_ratio
	screen_pos -= Vector2(2,4)
	
	var p_size = 6.0
	var col = Color(0.2, 1.0, 0.2)
	var dir = 0.0
	if not rotate_with_player and "rotation" in player:
		dir = player.rotation
	
	var points = PackedVector2Array([
		screen_pos + Vector2(0, -p_size).rotated(dir),
		screen_pos + Vector2(-p_size * 0.7, p_size).rotated(dir),
		screen_pos + Vector2(p_size * 0.7, p_size).rotated(dir)
	])
	
	draw_colored_polygon(points, col)
	draw_polyline(points, Color.BLACK, 1.0, true)

func _draw_visible_tiles() -> void:
	var main_layer = tilemap_layers[0]
	if not is_instance_valid(main_layer): return
		
	var tile_size_vec = main_layer.tile_set.tile_size
	
	# SIZE 1: Base Tile (Includes 0.5 padding to hide background gaps)
	var draw_rect_size = (Vector2(tile_size_vec) * world_scale) + Vector2(0.5, 0.5)
	
	# SIZE 2: Tint Overlay (Exact size, NO padding, to avoid bright overlapping lines)
	var tint_rect_size = (Vector2(tile_size_vec) * world_scale)
	
	var view_width_left = (minimap_size.x * icon_offset_ratio.x) / world_scale
	var view_width_right = (minimap_size.x * (1.0 - icon_offset_ratio.x)) / world_scale
	var view_height_top = (minimap_size.y * icon_offset_ratio.y) / world_scale
	var view_height_bottom = (minimap_size.y * (1.0 - icon_offset_ratio.y)) / world_scale
	
	var top_left_world = map_center - Vector2(view_width_left, view_height_top)
	var bottom_right_world = map_center + Vector2(view_width_right, view_height_bottom)
	var map_bounds = Rect2(Vector2.ZERO, minimap_size)

	for layer in tilemap_layers:
		if not is_instance_valid(layer) or not layer.visible: continue
		
		var top_left_local = layer.to_local(top_left_world)
		var bottom_right_local = layer.to_local(bottom_right_world)
		var top_left_map = layer.local_to_map(top_left_local)
		var bottom_right_map = layer.local_to_map(bottom_right_local)
		
		for x in range(top_left_map.x - 1, bottom_right_map.x + 2):
			for y in range(top_left_map.y - 1, bottom_right_map.y + 2):
				var coords = Vector2i(x, y)
				
				if fow_enabled and not _is_tile_explored(coords):
					continue 
				
				var source_id = layer.get_cell_source_id(coords)
				if source_id != -1:
					var local_pos = layer.map_to_local(coords)
					var global_pos = layer.to_global(local_pos)
					var screen_pos = _world_to_minimap(global_pos)
					
					# Bounds Check (Optimization)
					if circular_mask:
						if screen_pos.distance_to(minimap_size/2) > (min(minimap_size.x, minimap_size.y)/2):
							continue
					elif not map_bounds.has_point(screen_pos):
						continue 

					# 1. DRAW BASE (Using Padded Size to seal gaps)
					var base_rect = Rect2(screen_pos - draw_rect_size / 2, draw_rect_size)
					
					if use_textures:
						var source = layer.tile_set.get_source(source_id)
						if source is TileSetAtlasSource:
							var atlas_coords = layer.get_cell_atlas_coords(coords)
							var texture = source.texture
							var region = source.get_tile_texture_region(atlas_coords)
							draw_texture_rect_region(texture, base_rect, region)
						else:
							draw_rect(base_rect, default_tile_color)
					else:
						draw_rect(base_rect, default_tile_color)

					# 2. DRAW TINT (Using Exact Size to prevent white lines)
					if fow_enabled:
						var tint_rect = Rect2(screen_pos - tint_rect_size / 2, tint_rect_size)
						draw_rect(tint_rect, discovered_tint_color)
											
func _draw_registered_objects() -> void:
	var count = 0
	var map_bounds = Rect2(Vector2.ZERO, minimap_size)
	
	# Need main layer for fog checks
	var main_layer = tilemap_layers[0] if not tilemap_layers.is_empty() else null
	
	for group_name in active_objects:
		if not group_settings.has(group_name): continue
		var settings = group_settings[group_name]
		var list = active_objects[group_name]
		
		for i in range(list.size() - 1, -1, -1):
			var obj = list[i]
			if not is_instance_valid(obj):
				list.remove_at(i)
				continue
			if count >= max_objects_to_draw: return
			
			var world_pos = obj.global_position
			
			if fow_enabled and main_layer:
				var local_pos = main_layer.to_local(world_pos)
				var tile_pos = main_layer.local_to_map(local_pos)
				if not _is_tile_explored(tile_pos):
					continue
			
			var screen_pos = _world_to_minimap(world_pos)
			
			if circular_mask:
				if screen_pos.distance_to(minimap_size/2) > (min(minimap_size.x, minimap_size.y)/2):
					continue
			elif not map_bounds.has_point(screen_pos):
				continue
				
			_draw_icon(screen_pos, settings["size"], settings["color"], settings["shape"])
			count += 1

func _draw_icon(pos: Vector2, size: float, color: Color, shape: String) -> void:
	match shape:
		"circle": draw_circle(pos, size, color)
		"square": draw_rect(Rect2(pos - Vector2(size, size)/2, Vector2(size, size)), color)
		"diamond":
			var pts = PackedVector2Array([pos+Vector2(0,-size), pos+Vector2(size,0), pos+Vector2(0,size), pos+Vector2(-size,0)])
			draw_colored_polygon(pts, color)
		"triangle":
			var pts = PackedVector2Array([pos+Vector2(0,-size), pos+Vector2(-size,size), pos+Vector2(size,size)])
			draw_colored_polygon(pts, color)

# =========================================
# UTILITIES
# =========================================

func _world_to_minimap(world: Vector2) -> Vector2:
	var relative_from_player = world - map_center
	var scaled_offset = relative_from_player * world_scale
	var player_screen_pos = minimap_size * icon_offset_ratio
	return player_screen_pos + scaled_offset

# =========================================
# FOG & API
# =========================================

func _reveal_fog_at_position(world_pos: Vector2) -> void:
	if tilemap_layers.is_empty(): return
	var main_layer = tilemap_layers[0] # Use first layer as fog reference
	
	var local_pos = main_layer.to_local(world_pos) 
	var center_tile = main_layer.local_to_map(local_pos)
	
	var radius_tiles = int(fow_reveal_radius / float(main_layer.tile_set.tile_size.x))
	var radius_sq = radius_tiles * radius_tiles
	
	for x in range(center_tile.x - radius_tiles, center_tile.x + radius_tiles + 1):
		for y in range(center_tile.y - radius_tiles, center_tile.y + radius_tiles + 1):
			var tile_pos = Vector2i(x, y)
			if Vector2(tile_pos).distance_squared_to(Vector2(center_tile)) <= radius_sq:
				var fog_key = _get_fog_key(tile_pos)
				if not fog_explored.has(fog_key):
					fog_explored[fog_key] = true

func _is_tile_explored(tile_coords: Vector2i) -> bool:
	return fog_explored.has(_get_fog_key(tile_coords))

func _get_fog_key(tile_coords: Vector2i) -> Vector2i:
	if fow_resolution <= 1: return tile_coords
	return Vector2i(floor(tile_coords.x / float(fow_resolution)), floor(tile_coords.y / float(fow_resolution)))

func register_object(group: String, node: Node2D) -> void:
	if not active_objects.has(group): 
		active_objects[group] = []
	if node not in active_objects[group]:
		active_objects[group].append(node)

func remove_object(group: String, node: Node2D) -> void:
	if active_objects.has(group):
		active_objects[group].erase(node)

func get_fog_save_data() -> Dictionary:
	var data_array = []
	for key in fog_explored:
		data_array.append("%d,%d" % [key.x, key.y])
	return {"fog_data": data_array, "fow_resolution": fow_resolution}

func load_fog_save_data(data: Dictionary) -> void:
	fog_explored.clear()
	if not data.has("fog_data"): return
	if data.has("fow_resolution"): fow_resolution = data["fow_resolution"]
	for entry in data["fog_data"]:
		var parts = entry.split(",")
		if parts.size() == 2:
			fog_explored[Vector2i(int(parts[0]), int(parts[1]))] = true
	queue_redraw()
