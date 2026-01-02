extends StaticBody2D

@export var coin_reward: int = 5
@onready var coin = preload("res://levels/objects/coin/coin.tscn")

# 1. Reference the InteractiveArea2D child node
@onready var interactive_area: InteractiveArea2D = $InteractiveArea2D 
@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D

var is_opened: bool = false

func _ready():
	animated_sprite.play("close")
	
	# 2. Connect the signal from the area to the open function
	# You don't need _unhandled_input in this script at all!
	interactive_area.interacted.connect(attempt_open_chest)

# 3. This function is now called by the Signal, not by raw input
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
	AudioManager.play_sound("chest_open")
	await animated_sprite.animation_finished
	
	spawn_coins()

func spawn_coins():
	for n in coin_reward:
		var coin_instance = coin.instantiate()
		
		# 4. FIX: Add coins to the Scene Root, not the Chest.
		# If you add them to the Chest, they might rotate/scale with it.
		get_tree().current_scene.add_child(coin_instance)
		
		# set position to chest position
		coin_instance.global_position = global_position + Vector2(0, -20)
		
		# 5. FIX: apply_impulse is a FUNCTION, not a variable
		coin_instance.apply_impulse(Vector2(
			randf_range(-50, 50),
			randf_range(-150, -80)
		))
		
		await get_tree().create_timer(0.05).timeout
