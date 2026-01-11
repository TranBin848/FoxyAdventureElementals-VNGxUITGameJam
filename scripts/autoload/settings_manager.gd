extends Node

# Signals
signal particle_quality_changed(quality: int)
signal audio_settings_changed()

# Enums
enum ParticleQuality { OFF = 0, LOW = 1, HIGH = 2 }

# Variables
@export var particle_audio_interval: float = 1.0  # Seconds between audio plays

# Settings
var particle_quality: int = ParticleQuality.HIGH:
	set(value):
		particle_quality = value
		particle_quality_changed.emit(value)
		save_settings()

# Volume settings (0-100 range)
var music_volume: int = 100:
	set(value):
		music_volume = clampi(value, 0, 100)
		_apply_music_volume()
		audio_settings_changed.emit()
		save_settings()

var sfx_volume: int = 100:
	set(value):
		sfx_volume = clampi(value, 0, 100)
		_apply_sfx_volume()
		audio_settings_changed.emit()
		save_settings()

func _ready() -> void:
	load_settings()

func get_particle_ratio() -> float:
	match particle_quality:
		ParticleQuality.OFF:
			return 0.0
		ParticleQuality.LOW:
			return 0.3
		ParticleQuality.HIGH:
			return 1.0
		_:
			return 1.0

# Convert 0-100 range to decibels (-80 to 0 dB)
func _volume_to_db(volume: int) -> float:
	if volume <= 0:
		return -80.0  # Effectively muted
	else:
		# Linear to dB conversion: 0-100 -> -80 to 0 dB
		# Using a more natural logarithmic curve
		return linear_to_db(volume / 100.0)

func _apply_music_volume() -> void:
	var music_bus_idx = AudioServer.get_bus_index("Music")
	if music_volume <= 0:
		AudioServer.set_bus_mute(music_bus_idx, true)
	else:
		AudioServer.set_bus_mute(music_bus_idx, false)
		AudioServer.set_bus_volume_db(music_bus_idx, _volume_to_db(music_volume))

func _apply_sfx_volume() -> void:
	var sfx_bus_idx = AudioServer.get_bus_index("SFX")
	var ambience_bus_idx = AudioServer.get_bus_index("Ambience SFX")
	
	if sfx_volume <= 0:
		AudioServer.set_bus_mute(sfx_bus_idx, true)
		AudioServer.set_bus_mute(ambience_bus_idx, true)
	else:
		AudioServer.set_bus_mute(sfx_bus_idx, false)
		AudioServer.set_bus_mute(ambience_bus_idx, false)
		var volume_db = _volume_to_db(sfx_volume)
		AudioServer.set_bus_volume_db(sfx_bus_idx, volume_db)
		AudioServer.set_bus_volume_db(ambience_bus_idx, volume_db)

# Save settings to config file
func save_settings() -> void:
	var config = ConfigFile.new()
	config.set_value("graphics", "particle_quality", particle_quality)
	config.set_value("audio", "music_volume", music_volume)
	config.set_value("audio", "sfx_volume", sfx_volume)
	config.save("user://settings.cfg")

# Load settings from config file
func load_settings() -> void:
	var config = ConfigFile.new()
	var err = config.load("user://settings.cfg")
	
	if err == OK:
		particle_quality = config.get_value("graphics", "particle_quality", ParticleQuality.HIGH)
		music_volume = config.get_value("audio", "music_volume", 100)
		sfx_volume = config.get_value("audio", "sfx_volume", 100)
	else:
		# Apply defaults if no config file exists
		music_volume = 100
		sfx_volume = 100
		particle_quality = ParticleQuality.HIGH

# Helper functions to check if audio is effectively muted
func is_music_muted() -> bool:
	return music_volume <= 0

func is_sfx_muted() -> bool:
	return sfx_volume <= 0
