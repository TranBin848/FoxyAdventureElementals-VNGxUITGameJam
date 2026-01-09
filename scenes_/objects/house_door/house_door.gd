extends Node2D
class_name HouseDoor

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var collision_shape: CollisionShape2D = $StaticBody2D/CollisionShape2D

@export var is_open: bool

var logger: Logger = ConsoleLogger.new()

func _ready():
	if is_open:
		animated_sprite.play("open")
		collision_shape.disabled = true
		return
	animated_sprite.play("close")
	collision_shape.disabled = false
	
func open_door():
	animated_sprite.play("open")
	collision_shape.disabled = true

func close_door():
	animated_sprite.play("close")
	collision_shape.disabled = false
