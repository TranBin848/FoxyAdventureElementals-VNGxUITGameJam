extends RigidBody2D

@export var coin_amount: int = 1

func _ready() -> void:
	$Coin.play("idle")

func collect_coin():
	#linear_velocity = Vector2.ZERO
	#freeze = true
	#freeze_mode = RigidBody2D.FREEZE_MODE_STATIC
	GameManager.inventory_system.add_coin(1)
	$Coin.play("consumed")
	AudioManager.play_sound("coin_collect")
	queue_free()

func _on_body_entered(body: Node) -> void:
	if body is Player:
		collect_coin()
