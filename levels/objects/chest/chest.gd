extends InteractiveArea2D

@export var coin_reward: int = 5
@export var consumed_sfx: AudioStream = null

@onready var coin = preload("res://levels/objects/coin/coin.tscn")

var is_opened: bool = false

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D

func _ready():
	interacted.connect(_on_interacted)
	animated_sprite.play("close")

func _on_interacted():
	attempt_open_chest()

func attempt_open_chest():
	if is_opened:
		return
	if GameManager. inventory_system.has_key():
		open_chest()

func open_chest():
	if is_opened:
		return
	is_opened = true
	GameManager.inventory_system.use_key()
	animated_sprite.play("open")
	AudioPlayer.play_sound_once(consumed_sfx)
	await animated_sprite.animation_finished
	
	for n in coin_reward:
		var coin_instance = coin.instantiate()
		add_child(coin_instance)
		
		coin_instance.global_position = global_position + Vector2(0, -20)
		coin_instance._gravity = 980  # Changed from 'gravity'
		coin_instance.velocity = Vector2(
			randf_range(-50, 50), 
			randf_range(-150, -80)
		)
		
		await get_tree().create_timer(0.05).timeout
	
	print("Chest opened! You received ", coin_reward, " coins!")
