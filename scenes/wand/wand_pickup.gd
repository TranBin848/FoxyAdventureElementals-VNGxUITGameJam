extends Node2D

@onready var visuals: Node2D = $Visuals
@onready var halo_sprite: Sprite2D = $Visuals/HaloSprite
@onready var wand_sprite: Sprite2D = $Visuals/WandSprite 
@onready var interactive_area: InteractiveArea2D = $InteractiveArea2D
@onready var collision_shape: CollisionShape2D = $InteractiveArea2D/CollisionShape2D

# --- ASSETS ---
const TEX_NORMAL = preload("res://assets/foxy/fox_hat_wand/wand.png")
const TEX_SORROW = preload("res://assets/foxy/fox_hat_sorrow_wand/wand.png")
const TEX_SOUL = preload("res://assets/foxy/fox_hat_soul_wand/wand.png")

# --- GUIDE TRIGGER SETTINGS ---
@export_group("Guide Settings")
@export var guide_trigger_scene: PackedScene # Drag GuideTrigger.tscn here!
@export var guide_message: String = "Press F to Collect" # Text to show

# --- EXISTING SETTINGS ---
@export var float_height: float = 150.0 
@export var hover_duration: float = 5.0

var wand_level: int = 0 
var is_hovering: bool = false
var time_elapsed: float = 0.0

func _ready() -> void:
	
	interactive_area.visible = false
	if collision_shape: collision_shape.disabled = true
	
	halo_sprite.modulate.a = 0.0 
	halo_sprite.scale = Vector2.ZERO
	
	interactive_area.interacted.connect(_on_interacted)
	start_spawn_animation()
	
func _update_wand_texture() -> void:
	if not wand_sprite: return
	print(wand_level)
	match wand_level:
		Player.WandLevel.SORROW: wand_sprite.texture = TEX_SORROW
		Player.WandLevel.SOUL: wand_sprite.texture = TEX_SOUL
		_: wand_sprite.texture = TEX_NORMAL

func start_spawn_animation() -> void:
	visuals.position.y = 0 
	var tween = create_tween().set_parallel(true)
	tween.tween_property(visuals, "position:y", -float_height, 1.0).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(halo_sprite, "scale", Vector2(1.5, 1.5), 1.0) 
	tween.tween_property(halo_sprite, "modulate:a", 1.0, 1.0)
	
	tween.chain().tween_callback(func():
		is_hovering = true
		_start_enable_timer()
	)

func _process(delta: float) -> void:
	_update_wand_texture()
	if is_hovering:
		time_elapsed += delta
		visuals.position.y = -float_height + sin(time_elapsed * 2.0) * 5.0
		halo_sprite.rotation_degrees += 30 * delta
		var pulse = 1.5 + sin(time_elapsed * 3.0) * 0.1
		halo_sprite.scale = Vector2(pulse, pulse)

func _start_enable_timer() -> void:
	# Wait for the hover duration (5s)
	await get_tree().create_timer(hover_duration).timeout
	
	# 1. Flash effect
	var tween = create_tween()
	tween.tween_property(halo_sprite, "modulate", Color.WHITE * 2.0, 0.2) 
	tween.tween_property(halo_sprite, "modulate", Color.WHITE, 0.2) 
	
	# 2. Enable physical interaction
	interactive_area.visible = true
	if collision_shape: collision_shape.set_deferred("disabled", false)
	
	# 3. SPAWN GUIDE TRIGGER HERE
	spawn_guide_trigger()

func spawn_guide_trigger() -> void:
	if not guide_trigger_scene: return
	
	var guide = guide_trigger_scene.instantiate()
	
	# Set the text BEFORE adding to tree (so _ready picks it up)
	guide.guide_text = guide_message
	
	# Add as child so it moves with the wand (or add to parent to keep static)
	add_child(guide)
	
	# Adjust position if needed (e.g., slightly above the visual)
	#guide.position.y = -float_height - 20 

func _on_interacted() -> void:
	var player = GameManager.player
	if player and player.has_method("upgrade_wand_to"):
		player.upgrade_wand_to(wand_level)
		player.collect_wand()
		
		var tween = create_tween().set_parallel(true)
		tween.tween_property(self, "scale", Vector2.ZERO, 0.3).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
		tween.tween_property(self, "modulate:a", 0.0, 0.3)
		tween.chain().tween_callback(queue_free)
