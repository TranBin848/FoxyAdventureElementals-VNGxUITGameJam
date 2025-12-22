extends Control
class_name Minimap

@export_group("References")
@export var player: Node2D
@export var tilemap: TileMapLayer

@export_group("Minimap Settings")
@export var minimap_size: Vector2 = Vector2(250, 250)
@export var zoom_level: float = 0.3
@export var follow_player: bool = true
@export var circular_mask: bool = true

@export_group("Fog of War")
@export var fog_enabled: bool = true
@export var reveal_radius: float = 200.0
@export var fog_color: Color = Color(0, 0, 0, 0.95)
@export var fog_resolution: int = 64

@onready var subviewport_container: SubViewportContainer = $SubViewportContainer
@onready var subviewport: SubViewport = $SubViewportContainer/SubViewport
@onready var minimap_camera: Camera2D = $SubViewportContainer/SubViewport/MinimapCamera

# Fog data
var fog_image: Image
var fog_texture: ImageTexture
var fog_data: Array = []
var world_bounds: Rect2
var cell_size: float
var fog_overlay: ColorRect
var update_timer: float = 0.0

func _ready() -> void:
	custom_minimum_size = minimap_size
	size = minimap_size
	
	# Setup viewport
	subviewport_container.custom_minimum_size = minimap_size
	subviewport_container.size = minimap_size
	subviewport_container.stretch = true
	
	subviewport.size = minimap_size
	subviewport.transparent_bg = true
	subviewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	subviewport.world_2d = get_viewport().world_2d
	
	# Setup camera
	minimap_camera.enabled = true
	minimap_camera.zoom = Vector2.ONE * zoom_level
	
	# Initialize
	if fog_enabled:
		_initialize_fog()
	if circular_mask:
		_apply_circular_mask()
	_add_border()
	set_process(true)

func _process(delta: float) -> void:
	if follow_player and player and is_instance_valid(minimap_camera):
		minimap_camera.global_position = player.global_position
	
	if fog_enabled:
		update_timer += delta
		if update_timer >= 0.1:  # Update every 0.1s for performance
			_update_fog_around_player()
			update_timer = 0.0

func _initialize_fog() -> void:
	if tilemap:
		_calculate_world_bounds()
	else:
		world_bounds = Rect2(-2000, -2000, 4000, 4000)
	
	cell_size = max(world_bounds.size.x, world_bounds.size.y) / float(fog_resolution)
	
	# Initialize fog grid
	fog_data.clear()
	for y in range(fog_resolution):
		var row = []
		for x in range(fog_resolution):
			row.append(false)
		fog_data.append(row)
	
	# Create fog image (black = fog, transparent = revealed)
	fog_image = Image.create(fog_resolution, fog_resolution, false, Image.FORMAT_RGBA8)
	fog_image.fill(fog_color)
	fog_texture = ImageTexture.create_from_image(fog_image)
	
	_create_fog_overlay()
	
	# Set camera limits
	minimap_camera.limit_left = world_bounds.position.x
	minimap_camera.limit_top = world_bounds.position.y
	minimap_camera.limit_right = world_bounds.end.x
	minimap_camera.limit_bottom = world_bounds.end.y
	
	print("🗺️ Fog initialized: %dx%d grid, bounds: %s" % [fog_resolution, fog_resolution, world_bounds])

func _calculate_world_bounds() -> void:
	var used_cells = tilemap.get_used_cells()  # Layer 0
	if used_cells.is_empty():
		world_bounds = Rect2(-2000, -2000, 4000, 4000)
		return
	
	var min_pos = used_cells[0]
	var max_pos = used_cells[0]
	
	for cell in used_cells:
		min_pos.x = min(min_pos.x, cell.x)
		min_pos.y = min(min_pos.y, cell.y)
		max_pos.x = max(max_pos.x, cell.x)
		max_pos.y = max(max_pos.y, cell.y)
	
	var tile_size = tilemap.tile_set.tile_size
	world_bounds = Rect2(
		Vector2(min_pos) * Vector2(tile_size),
		Vector2(max_pos - min_pos + Vector2i.ONE) * Vector2(tile_size)
	)

func _update_fog_around_player() -> void:
	if not player:
		return
	
	var player_pos = player.global_position
	var needs_update = false
	var cells_to_reveal = int(ceil(reveal_radius / cell_size))
	var player_grid_pos = _world_to_grid(player_pos)
	
	for dy in range(-cells_to_reveal, cells_to_reveal + 1):
		for dx in range(-cells_to_reveal, cells_to_reveal + 1):
			var gx = player_grid_pos.x + dx
			var gy = player_grid_pos.y + dy
			
			if gx < 0 or gx >= fog_resolution or gy < 0 or gy >= fog_resolution:
				continue
			
			var cell_world_pos = _grid_to_world(Vector2i(gx, gy))
			if player_pos.distance_to(cell_world_pos) <= reveal_radius:
				if not fog_data[gy][gx]:
					fog_data[gy][gx] = true
					needs_update = true
	
	if needs_update:
		_update_fog_texture()

func _update_fog_texture() -> void:
	for y in range(fog_resolution):
		for x in range(fog_resolution):
			if fog_data[y][x]:
				fog_image.set_pixel(x, y, Color.TRANSPARENT)
			else:
				fog_image.set_pixel(x, y, fog_color)
	fog_texture.update(fog_image)

func _create_fog_overlay() -> void:
	fog_overlay = ColorRect.new()
	fog_overlay.color = Color.TRANSPARENT
	fog_overlay.anchors_preset = Control.PRESET_FULL_RECT
	fog_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	fog_overlay.z_index = 5  # Above tilemap, below border
	
	var shader_material = ShaderMaterial.new()
	shader_material.shader = _create_fog_shader()
	fog_overlay.material = shader_material
	
	subviewport.add_child(fog_overlay)

func _create_fog_shader() -> Shader:
	var shader = Shader.new()
	shader.code = """
	shader_type canvas_item;
	
	uniform sampler2D fog_texture : hint_default_white;
	uniform vec2 texture_scale;
	
	void fragment() {
		vec2 fog_uv = UV * texture_scale;
		vec4 fog_sample = texture(fog_texture, fog_uv);
		COLOR = fog_sample;
		COLOR.a *= texture(TEXTURE, UV).a;  // Preserve underlying alpha
	}
	"""
	return shader

func _world_to_grid(world_pos: Vector2) -> Vector2i:
	var relative = world_pos - world_bounds.position
	var normalized = relative / world_bounds.size
	var grid_pos = normalized * (fog_resolution - 1)
	return Vector2i(
		clampi(int(grid_pos.x), 0, fog_resolution - 1),
		clampi(int(grid_pos.y), 0, fog_resolution - 1)
	)

func _grid_to_world(grid_pos: Vector2i) -> Vector2:
	var normalized = Vector2(grid_pos) / (fog_resolution - 1)
	return world_bounds.position + normalized * world_bounds.size

func _apply_circular_mask() -> void:
	var shader_code = """
	shader_type canvas_item;
	uniform float radius : hint_range(0.0, 1.0) = 0.48;
	uniform float edge_softness : hint_range(0.0, 0.1) = 0.02;
	
	void fragment() {
		vec2 uv = UV - vec2(0.5);
		float dist = length(uv);
		float mask = smoothstep(radius, radius - edge_softness, dist);
		COLOR.a *= mask;
	}
	"""
	
	var shader = Shader.new()
	shader.code = shader_code
	var material = ShaderMaterial.new()
	material.shader = shader
	subviewport_container.material = material

func _add_border() -> void:
	var border = ColorRect.new()
	border.color = Color.BLACK
	border.anchors_preset = Control.PRESET_FULL_RECT
	border.mouse_filter = Control.MOUSE_FILTER_IGNORE
	border.material = ShaderMaterial.new()
	border.material.shader = _create_border_shader()
	add_child(border)

func _create_border_shader() -> Shader:
	var shader = Shader.new()
	shader.code = """
	shader_type canvas_item;
	
	uniform float border_width : hint_range(0.0, 0.1) = 0.04;
	uniform vec4 border_color : hint_color = vec4(1.0);
	uniform float radius : hint_range(0.0, 0.5) = 0.48;
	
	void fragment() {
		vec2 uv = UV - vec2(0.5);
		float dist = length(uv);
		float inner_radius = radius - border_width;
		
		float mask = smoothstep(inner_radius, radius, dist);
		COLOR = mix(Color(0.0), border_color, mask);
		COLOR.a *= mask;
	}
	"""
	return shader

# ===== PUBLIC API =====
func reveal_area(world_pos: Vector2, radius: float) -> void:
	var cells_to_reveal = int(ceil(radius / cell_size))
	var grid_pos = _world_to_grid(world_pos)
	
	for dy in range(-cells_to_reveal, cells_to_reveal + 1):
		for dx in range(-cells_to_reveal, cells_to_reveal + 1):
			var gx = grid_pos.x + dx
			var gy = grid_pos.y + dy
			
			if gx < 0 or gx >= fog_resolution or gy < 0 or gy >= fog_resolution:
				continue
			
			var cell_world_pos = _grid_to_world(Vector2i(gx, gy))
			if world_pos.distance_to(cell_world_pos) <= radius:
				fog_data[gy][gx] = true
	
	_update_fog_texture()

func reset_fog() -> void:
	for y in range(fog_resolution):
		for x in range(fog_resolution):
			fog_data[y][x] = false
	_update_fog_texture()

func save_fog_data() -> Dictionary:
	var saved_data = []
	for y in range(fog_resolution):
		for x in range(fog_resolution):
			if fog_data[y][x]:
				saved_data.append(Vector2i(x, y))
	return {"explored_cells": saved_data, "bounds": world_bounds}

func load_fog_data(data: Dictionary) -> void:
	reset_fog()
	world_bounds = data.get("bounds", world_bounds)
	
	for cell in data.get("explored_cells", []):
		if cell.x >= 0 and cell.x < fog_resolution and cell.y >= 0 and cell.y < fog_resolution:
			fog_data[cell.y][cell.x] = true
	_update_fog_texture()
