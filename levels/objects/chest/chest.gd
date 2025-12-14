extends Area2D

@export var coin_reward: int = 5
@export var consumed_sfx: AudioStream = null

@onready var coin = preload("res://levels/objects/coin/coin.tscn")

var is_opened: bool = false
var player_in_area: bool = false

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D

func _ready():
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	animated_sprite.play("close")
	set_process_unhandled_input(false)

func _unhandled_input(event):
	if event.is_action_pressed("interact"):
		attempt_open_chest()
		get_viewport().set_input_as_handled()

func _on_body_entered(body: Node2D):
	if body.name == "Player" or body.has_method("set_speed_multiplier"):
		player_in_area = true
		set_process_unhandled_input(true)

func _on_body_exited(body: Node2D):
	if body.name == "Player" or body.has_method("set_speed_multiplier"):
		player_in_area = false
		set_process_unhandled_input(false)

func attempt_open_chest():
	if is_opened:
		return
	
	if not player_in_area:
		return
	
	if GameManager.inventory_system.has_key():
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
		coin_instance._gravity = 980
		coin_instance.velocity = Vector2(
			randf_range(-50, 50),
			randf_range(-150, -80)
		)
		
		await get_tree().create_timer(0.05).timeout
