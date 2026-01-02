extends Area2D
class_name HitArea2D

@export var damage = 5
@export var elemental_type: ElementsEnum.Elements = ElementsEnum.Elements.NONE
var player: Player = null

signal hitted(area)

func _init() -> void:
	area_entered.connect(_on_area_entered)

func _ready() -> void:
	# Get player reference from parent hierarchy (Player/Direction/HitArea2D)
	player = get_parent().get_parent() as Player
	if not player:
		push_error("HitArea2D: Could not find Player in parent hierarchy")

func hit(hurt_area):
	if hurt_area.has_method("take_damage"):
		var hit_dir: Vector2 = hurt_area.global_position - global_position
		
		# Ensure player reference is available
		if not player:
			player = get_parent().get_parent() as Player
		
		# Set damage based on current weapon
		if player and player.current_weapon == player.WeaponType.BLADE:
			damage = 5
		elif player and player.current_weapon == player.WeaponType.WAND:
			damage = 1
		else:
			damage = 5  # Default damage if player not found
		
		hurt_area.take_damage(hit_dir.normalized(), damage, elemental_type)

func _on_area_entered(area):
	hit(area)
	hitted.emit(area)
