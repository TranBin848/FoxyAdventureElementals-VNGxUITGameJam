extends InteractiveArea2D

var velocity = Vector2.ZERO
var _gravity = 0

@export var coin_amount: int = 1

@onready var ground_ray = $RayCast2D

func _ready() -> void:
	interaction_available.connect(_on_interaction_available)
	$Coin.play("idle")
	super._ready()


func _physics_process(delta):
	# Apply gravity
	velocity.y += _gravity * delta
	
	# Move the coin
	position += velocity * delta
	
	# Check ground collision with raycast
	if ground_ray.is_colliding():
		var collision_point = ground_ray.get_collision_point()
		
		# Snap to ground
		global_position.y = collision_point.y
		
		# Bounce effect
		velocity.y = -velocity.y * 0.5
		velocity.x *= 0.8
		
		# Stop if too slow
		if abs(velocity.y) < 50 and abs(velocity.x) < 50:
			velocity = Vector2.ZERO
			set_physics_process(false)  # Stop physics when landed


func collect_coin():
	GameManager.inventory_system.add_coin(1)
	$Coin.play("consumed")
	AudioManager.play_sound("item_collect")
	$Coin.animation_finished.connect(queue_free)

func _on_interaction_available() -> void:
	collect_coin()
