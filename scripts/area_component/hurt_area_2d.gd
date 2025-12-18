extends Area2D
class_name HurtArea2D

# signal when hurt
signal hurt(direction: Vector2, damage: float)

var owner_character: Node2D  # Reference to the character that owns this area

func _ready() -> void:
	# Auto-detect owner (assumes HurtArea2D is child of Direction which is child of Character)
	if get_parent() and get_parent().get_parent():
		owner_character = get_parent().get_parent()


# called when take damage
func take_damage(direction: Vector2, damage: float, elemental_type: int = 0):
	hurt.emit(direction, damage, elemental_type)
