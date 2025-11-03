extends Area2D
class_name HitArea2D

@export var damage = 1
signal hitted(area)

var character: BaseCharacter  # Reference to parent character

func _init() -> void:
	area_entered.connect(_on_area_entered)

func _ready() -> void:
	# Get reference to parent BaseCharacter
	character = get_parent().get_parent() as BaseCharacter
	if character == null:
		pass

func hit(hurt_area):
	if hurt_area.has_method("take_damage"):
		var hit_dir: Vector2 = hurt_area.global_position - global_position
		# Pass elemental_type from the character
		hurt_area.take_damage(hit_dir.normalized(), damage, character.elemental_type)

func _on_area_entered(area):
	hit(area)
	hitted.emit(area)
