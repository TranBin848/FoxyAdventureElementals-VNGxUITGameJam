extends ProjectileBase
class_name WoodenCloneProjectile

@export var spawn_offset_x: float = 16.0
@export var spawn_offset_y: float = 0.0
@export var clone_lifetime_sec: float = 10.0
@export var clone_anim: String = "wand"

@onready var clone_body: CharacterBody2D = $CloneCharacter
@onready var clone_sprite: AnimatedSprite2D = $CloneBody2D/Direction/AnimatedSprite2D

var center_position: Vector2
var is_active: bool = false

func _ready() -> void:
	rotation = 0.0  # cancel ProjectileBase rotation

	var dir_x := direction.x
	if dir_x == 0:
		dir_x = 1

	global_position += Vector2(spawn_offset_x * dir_x, spawn_offset_y)
	center_position = global_position

	if clone_sprite:
		clone_sprite.flip_h = dir_x < 0
		clone_sprite.flip_v = false
		clone_sprite.play(clone_anim)

	speed = 0
	set_physics_process(false)

	if GameManager.player and GameManager.player.has_method("go_invisible"):
		GameManager.player.go_invisible(clone_lifetime_sec)

	_start_lifetime()

func _start_lifetime() -> void:
	is_active = true
	await get_tree().create_timer(clone_lifetime_sec).timeout
	queue_free()
