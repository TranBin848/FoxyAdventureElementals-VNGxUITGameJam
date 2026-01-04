class_name BossHealthBar
extends Control

@export var boss_node: Node2D

@export_group("Elemental Overlays")
@export var metal_overlay: Texture2D
@export var wood_overlay: Texture2D
@export var water_overlay: Texture2D
@export var fire_overlay: Texture2D
@export var earth_overlay: Texture2D

## The actual bar to update.
@onready var health_bar: TextureProgressBar = $TextureProgressBar

var health_tween: Tween
var element_textures = {}
@export var transition_duration: float = 0.5
func _ready() -> void:
	if not health_bar:
		push_error("BossHealthBar: No TextureProgressBar found!")
		return
	
	# Map the Enum values to the Textures
	element_textures = {
		ElementsEnum.Elements.METAL: metal_overlay,
		ElementsEnum.Elements.WOOD: wood_overlay,
		ElementsEnum.Elements.WATER: water_overlay,
		ElementsEnum.Elements.FIRE: fire_overlay,
		ElementsEnum.Elements.EARTH: earth_overlay
	}
		
	health_bar.hide()
	health_bar.texture_over = null
	health_bar.value = 100
	
	if boss_node:
		_connect_signals()
	else:
		push_warning("BossHealthBar: No boss_node assigned in Inspector.")

func _connect_signals() -> void:
	if boss_node.has_signal("health_percent_changed"):
		boss_node.health_percent_changed.connect(_update_health)
	
	if boss_node.has_signal("phase_changed"):
		boss_node.phase_changed.connect(_on_phase_changed)
		
	if boss_node.has_signal("fight_started"):
		boss_node.fight_started.connect(_on_fight_started)
		
	if boss_node.has_signal("boss_died"):
		boss_node.boss_died.connect(_on_boss_died)

# --- Signal Receivers ---

func _update_health(new_value_percent: float) -> void:
	if health_tween:
		health_tween.kill()
		
	health_tween = create_tween()
	
	#print(name + str(new_value_percent))
	
	health_tween.tween_property(health_bar, "value", new_value_percent, 0.2)\
		.set_trans(Tween.TRANS_SINE)\
		.set_ease(Tween.EASE_OUT)

func _on_fight_started() -> void:
	health_bar.show()

func _on_boss_died() -> void:
	health_bar.hide()

func _on_phase_changed(new_phase_index: int) -> void:
	_update_overlay(true)

func _update_overlay(animated: bool = true) -> void:
	if not "elemental_type" in boss_node: return
	
	var type = boss_node.elemental_type
	if not element_textures.has(type): return
	
	var new_texture = element_textures[type]
	var old_texture = health_bar.texture_over

	# Optimization: If texture is the same, do nothing
	if old_texture == new_texture: return

	# Setup: If not animated (start of fight), just snap to new
	if not animated:
		health_bar.texture_over = new_texture
		return

	# --- FADE OUT & FILL UP ANIMATION ---
	
	# 1. Create the "Ghost" (Old texture fading out)
	var disappearing_rect = TextureProgressBar.new()
	if old_texture:
		disappearing_rect.texture_progress = old_texture
		# Force the ghost to scale to the parent's bounding box
		disappearing_rect.fill_mode = TextureProgressBar.FILL_TOP_TO_BOTTOM
		disappearing_rect.value = 100
		disappearing_rect.nine_patch_stretch = true 
		disappearing_rect.stretch_margin_bottom = 0 
		disappearing_rect.stretch_margin_left = 0
		disappearing_rect.stretch_margin_right = 0
		disappearing_rect.stretch_margin_top = 0
		
		disappearing_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
		disappearing_rect.size = health_bar.size
		disappearing_rect.name = "disappearing_rect"
		
		# Add child FIRST, then set anchors (anchors need a parent to work)
		health_bar.add_child(disappearing_rect)
		disappearing_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
		 
	# 2. Create the "Filler" (New texture filling up)
	var filler_bar = TextureProgressBar.new()
	filler_bar.texture_progress = new_texture 
	filler_bar.fill_mode = TextureProgressBar.FILL_BOTTOM_TO_TOP
	filler_bar.value = 0 # Start empty
	
	# Crucial: Enable scaling so it fits the small bar instead of original texture size
	filler_bar.nine_patch_stretch = true 
	filler_bar.stretch_margin_bottom = 0 
	filler_bar.stretch_margin_left = 0
	filler_bar.stretch_margin_right = 0
	filler_bar.stretch_margin_top = 0
	filler_bar.size = health_bar.size
	
	filler_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	filler_bar.name = "filler_bar"
	# Add child FIRST, then set anchors
	health_bar.add_child(filler_bar)
	filler_bar.set_anchors_preset(Control.PRESET_FULL_RECT)

	# 3. Clear the main bar's overlay temporarily so it doesn't double up
	health_bar.texture_over = null

	# 4. Animate!
	var tween = create_tween().set_parallel(true)
	
	# A: Fade out the ghost (Old)
	if old_texture:
		tween.tween_property(disappearing_rect, "value", 0.0, transition_duration)\
		.set_trans(Tween.TRANS_CUBIC)\
		.set_ease(Tween.EASE_OUT)
		
	# B: Fill up the filler (New)
	tween.tween_property(filler_bar, "value", 100.0, transition_duration)\
		.set_trans(Tween.TRANS_CUBIC)\
		.set_ease(Tween.EASE_OUT)

	# 5. Cleanup when done
	tween.chain().tween_callback(func():
		# Set the real overlay to the new texture
		health_bar.texture_over = new_texture
		# Delete temp nodes
		disappearing_rect.queue_free()
		filler_bar.queue_free()
	)
