extends Node

# Signals
signal particle_quality_changed(quality: int)
signal audio_settings_changed()

# Enums
enum ParticleQuality { OFF = 0, LOW = 1, HIGH = 2 }

# Settings
var particle_quality: int = ParticleQuality.HIGH:
	set(value):
		particle_quality = value
		particle_quality_changed.emit(value)
		save_settings()

var music_enabled: bool = true:
	set(value):
		music_enabled = value
		AudioServer.set_bus_mute(AudioServer.get_bus_index("Music"), not value)
		audio_settings_changed.emit()
		save_settings()

var sfx_enabled: bool = true:
	set(value):
		sfx_enabled = value
		AudioServer.set_bus_mute(AudioServer.get_bus_index("SFX"), not value)
		AudioServer.set_bus_mute(AudioServer.get_bus_index("Ambience SFX"), not value)

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

# Save settings to config file
func save_settings() -> void:
	var config = ConfigFile.new()
	config.set_value("graphics", "particle_quality", particle_quality)
	config.set_value("audio", "music_enabled", music_enabled)
	config.set_value("audio", "sfx_enabled", sfx_enabled)
	config.save("user://settings.cfg")

# Load settings from config file
func load_settings() -> void:
	var config = ConfigFile.new()
	var err = config.load("user://settings.cfg")
	
	if err == OK:
		particle_quality = config.get_value("graphics", "particle_quality", ParticleQuality.HIGH)
		music_enabled = config.get_value("audio", "music_enabled", true)
		sfx_enabled = config.get_value("audio", "sfx_enabled", true)
	else:
		# Apply defaults if no config file exists
		music_enabled = true
		sfx_enabled = true
		particle_quality = ParticleQuality.HIGH
