extends Area2D
class_name HitArea2D

@export var damage = 20
@export var elemental_type: ElementsEnum.Elements = ElementsEnum.Elements.NONE
var owner_character: Node2D = null

signal hitted(area)

func _init() -> void:
	area_entered.connect(_on_area_entered)

func _ready() -> void:
	# Get player reference from parent hierarchy (Player/Direction/HitArea2D)
	#player = get_parent().get_parent() as Player
	owner_character = get_parent()#.get_parent()
	print("owner character: " + str(owner_character))
	#if not player:
		#push_error("HitArea2D: Could not find Player in parent hierarchy")

func hit(hurt_area):
	if hurt_area.has_method("take_damage"):
		var hit_dir: Vector2 = hurt_area.global_position - global_position
		
		# Ensure player reference is available
		#if not player:
			#player = get_parent().get_parent() as Player
		
		hurt_area.take_damage(hit_dir.normalized(), damage, elemental_type, owner_character)

func _on_area_entered(area):
	hit(area)
	hitted.emit(area)
