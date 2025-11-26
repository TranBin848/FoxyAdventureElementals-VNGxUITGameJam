extends Node

var player: AudioStreamPlayer2D

func _ready() -> void:
	# Create the audio player
	player = AudioStreamPlayer2D.new()
	player.max_distance = 999999
	add_child(player)

	# Set which audio bus this player uses
	player.bus = "SFX"

func play_sound_once(sound: AudioStream) -> void:
	if sound == null:
		return

	player.stream = sound
	player.stop()
	player.pitch_scale = 1
	player.play()
