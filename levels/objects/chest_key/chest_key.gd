extends InteractiveArea2D

@export var key_amount: int = 1

func _ready() -> void:
	interaction_available.connect(_on_interaction_available)
	super._ready()

func collect_key():
	GameManager.inventory_system.add_key(1)
	AudioManager.play_sound("key_collect")
	queue_free()

func _on_interaction_available() -> void:
	collect_key()
