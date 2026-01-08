extends Node2D

@onready var area_point_light_2d: PointLight2D = $AreaPointLight2D
@onready var shadow_cast_point_light_2d: PointLight2D = $ShadowCastPointLight2D

# Customizable duration for the light animation
@export var animation_duration: float = 0.5
@export var is_on: bool = true

# Variables to remember the original settings from the scene editor
var _original_area_energy: float
var _original_area_scale: float
var _original_shadow_energy: float
var _original_shadow_scale: float

var _tween: Tween

func _ready() -> void:
	add_to_group("light_source")
	
	# 1. Capture the values currently set in the Inspector/Scene
	_original_area_energy = area_point_light_2d.energy
	_original_area_scale = area_point_light_2d.texture_scale
	
	_original_shadow_energy = shadow_cast_point_light_2d.energy
	_original_shadow_scale = shadow_cast_point_light_2d.texture_scale
	
	if not is_on:
		turn_off()

func turn_on(_body = null) -> void:
	# Kill any running animation to prevent conflicts
	if _tween: _tween.kill()
	
	# Create a new tween running in parallel (so scale and energy animate together)
	_tween = create_tween().set_parallel(true)
	_tween.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	
	# Animate back to the remembered original values
	_tween.tween_property(area_point_light_2d, "energy", _original_area_energy, animation_duration)
	_tween.tween_property(area_point_light_2d, "texture_scale", _original_area_scale, animation_duration)
	
	_tween.tween_property(shadow_cast_point_light_2d, "energy", _original_shadow_energy, animation_duration)
	_tween.tween_property(shadow_cast_point_light_2d, "texture_scale", _original_shadow_scale, animation_duration)

func turn_off(_body = null) -> void:
	if _tween: _tween.kill()
	
	_tween = create_tween().set_parallel(true)
	_tween.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	
	# Animate values down to 0 (shrink and darken)
	_tween.tween_property(area_point_light_2d, "energy", 0.0, animation_duration)
	_tween.tween_property(area_point_light_2d, "texture_scale", 0.0, animation_duration)
	
	_tween.tween_property(shadow_cast_point_light_2d, "energy", 0.0, animation_duration)
	_tween.tween_property(shadow_cast_point_light_2d, "texture_scale", 0.0, animation_duration)
