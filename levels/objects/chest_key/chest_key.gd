extends InteractiveArea2D

@export var key_amount: int = 1
@export var consumed_sfx: AudioStream = null

func _ready() -> void:
	interaction_available.connect(_on_interaction_available)
	super._ready()

func collect_key():
	GameManager.inventory_system.add_key(1)
	AudioPlayer.play_sound_once(consumed_sfx)
	AudioPlayer.player.pitch_scale=0.6
	queue_free()

func _on_interaction_available() -> void:
	collect_key()
