extends Node2D
class_name WandPickup

@onready var visuals: Node2D = $Visuals
@onready var halo_sprite: Sprite2D = $Visuals/HaloSprite
@onready var wand_sprite: Sprite2D = $Visuals/WandSprite
@onready var detection_area: Area2D = $DetectionArea2D
@onready var detection_shape: CollisionShape2D = $DetectionArea2D/CollisionShape2D

# --- ASSETS ---
const TEX_NORMAL = preload("res://assets/foxy/fox_hat_wand/wand.png")
const TEX_SORROW = preload("res://assets/foxy/fox_hat_sorrow_wand/wand.png")
const TEX_SOUL = preload("res://assets/foxy/fox_hat_soul_wand/wand.png")

# --- FLOAT / ATTRACT SETTINGS ---
@export var float_height: float = 150.0
@export var hover_duration: float = 5.0
@export var attract_speed: float = 360.0
@export var collect_distance: float = 28.0

var _wand_level: Player.WandLevel = Player.WandLevel.NORMAL
var is_hovering := false
var is_attracted := false
var time_elapsed := 0.0
var target_player: Player = null
var hover_base_y: float
var spawn_tween: Tween

func _ready() -> void:
	detection_area.monitoring = false
	if detection_shape:
		detection_shape.disabled = true
	
	halo_sprite.modulate.a = 0.0
	halo_sprite.scale = Vector2.ZERO
	
	detection_area.body_entered.connect(_on_player_detected)
	
	# WAIT one frame for parent to set our position
	await get_tree().process_frame
	
	print("🪄 WandPickup spawned at position: ", global_position)
	start_spawn_animation()

func start_spawn_animation() -> void:
	var start_y = global_position.y
	var target_y = start_y - float_height
	
	# Save the TARGET Y for hovering (not the starting position)
	hover_base_y = target_y
	
	print("🪄 Hover base Y set to: ", hover_base_y)
	
	spawn_tween = create_tween()
	# Float up
	spawn_tween.tween_property(
		self,
		"global_position:y",
		target_y,
		0.5
	).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	
	# Animate halo at the same time
	spawn_tween.parallel().tween_property(halo_sprite, "scale", Vector2(1.5, 1.5), 0.5)
	spawn_tween.parallel().tween_property(halo_sprite, "modulate:a", 1.0, 0.5)
	
	# Wait for the tween to finish
	await spawn_tween.finished
	
	print("🪄 Starting hover at Y: ", global_position.y)
	
	is_hovering = true
	_start_enable_timer()

func _process(delta: float) -> void:
	if is_hovering and not is_attracted:
		time_elapsed += delta
		global_position.y = hover_base_y + sin(time_elapsed * 2.0) * 5.0
		halo_sprite.rotation_degrees += 30 * delta

func _start_enable_timer() -> void:
	await get_tree().create_timer(hover_duration).timeout
	detection_area.monitoring = true
	if detection_shape:
		detection_shape.set_deferred("disabled", false)

func _on_player_detected(body: Node2D) -> void:
	if body is Player and not is_attracted:
		# Kill spawn tween defensively
		if spawn_tween and spawn_tween.is_valid():
			spawn_tween.kill()
		is_hovering = false
		is_attracted = true
		target_player = body
		time_elapsed = 0.0

func _physics_process(delta: float) -> void:
	if is_attracted and is_instance_valid(target_player):
		var dir := (target_player.global_position - global_position).normalized()
		global_position += dir * attract_speed * delta
		if global_position.distance_to(target_player.global_position) < collect_distance:
			_collect_wand(target_player)

func _collect_wand(player: Player) -> void:
	is_attracted = false
	detection_area.monitoring = false
	if detection_shape:
		detection_shape.set_deferred("disabled", true)
	
	player.collect_wand(_wand_level)
	
	var tween = create_tween().set_parallel(true)
	tween.tween_property(self, "scale", Vector2.ZERO, 0.3)\
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
	tween.tween_property(self, "modulate:a", 0.0, 0.3)
	tween.chain().tween_callback(queue_free)

func set_wand_level(level: Player.WandLevel) -> void:
	_wand_level = level
	match level:
		Player.WandLevel.SORROW:
			wand_sprite.texture = TEX_SORROW
		Player.WandLevel.SOUL:
			wand_sprite.texture = TEX_SOUL
		_:
			wand_sprite.texture = TEX_NORMAL
