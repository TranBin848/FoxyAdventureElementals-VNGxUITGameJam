extends Area2D
class_name HitArea2D

@export var damage = 1
@export var elemental_type: int = 0 #0: none, 1: fire, 2: earth, 3: water
signal hitted(area)

func _init() -> void:
	area_entered.connect(_on_area_entered)

func hit(hurt_area):
	if hurt_area.has_method("take_damage"):
		var hit_dir: Vector2 = hurt_area.global_position - global_position
		hurt_area.take_damage(hit_dir.normalized(), damage, elemental_type)

func _on_area_entered(area):
	hit(area)
	hitted.emit(area)
