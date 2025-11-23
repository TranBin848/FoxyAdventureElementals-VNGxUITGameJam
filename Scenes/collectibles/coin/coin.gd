extends InteractiveArea2D

@export var coin_amount: int = 1

func _ready() -> void:
	interaction_available.connect(_on_interaction_available)
	super._ready ()

func collect_coin():
	GameManager.inventory_system.add_coin(1)
	$Coin.play("collected")
	await $Coin.animation_finished
	queue_free()

func _on_interaction_available() -> void:
	collect_coin()
