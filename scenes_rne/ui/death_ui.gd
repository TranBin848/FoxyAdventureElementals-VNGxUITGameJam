extends Control

@onready var animation_player: AnimationPlayer = $AnimationPlayer

@export var defeat_sfx: AudioStream = null

@export var player: Player = null

func _ready() -> void:
	player.connect("died", Callable(self, "show_ui"))

func show_ui() -> void:
	show()
	animation_player.play("show_death_ui")
	BackgroundMusic.stop()
	AudioPlayer.play_sound_once(defeat_sfx)
