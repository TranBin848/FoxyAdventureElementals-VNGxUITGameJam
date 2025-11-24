extends InteractiveArea2D

@export var coin_reward: int = 5

var is_opened: bool = false

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var coin_scene: PackedScene = preload("../../collectibles/coin/coin.tscn")

func _ready():
	interacted.connect(_on_interacted)
	animated_sprite.play("close")

func _on_interacted():
	attempt_open_chest()

func attempt_open_chest():
	if is_opened:
		return
	if GameManager.inventory_system.has_key():
		open_chest()

func open_chest():
	if is_opened:
		return

	is_opened = true
	GameManager.inventory_system.use_key()
	animated_sprite.play("open")
	await animated_sprite.animation_finished
	spawn_coins()
	print("Chest opened! Coins scattered!")

func spawn_coins():
	for i in range(coin_reward):
		var coin = coin_scene.instantiate()
		var random_offset = Vector2(randf_range(-30, 30), randf_range(0, 15))
		coin.global_position = global_position + random_offset
		get_parent().add_child(coin)
