extends Node2D

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var collision_shape: CollisionShape2D = $StaticBody2D/CollisionShape2D

var logger: Logger = ConsoleLogger.new()

func _ready():
	animated_sprite.play("close")
	collision_shape.disabled = false

func open_door():
	animated_sprite.play("open")
	collision_shape.disabled = true

func close_door():
	animated_sprite.play("close")
	collision_shape.disabled = false
