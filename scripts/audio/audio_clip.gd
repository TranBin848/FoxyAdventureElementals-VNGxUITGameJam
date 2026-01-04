class_name AudioClip
extends Resource

## Resource đại diện cho một audio clip

@export var clip_id: String = ""
# Primary stream (acts as fallback or the only sound if no variations exist)
@export var stream: AudioStream = null

# NEW: List of variations (e.g., 5 different footstep sounds)
@export var variations: Array[AudioStream] = []

@export var volume_db: float = 0.0
@export var randomize_pitch: bool = false
@export_range(0.1, 2.0) var pitch_min: float = 0.9
@export_range(0.1, 2.0) var pitch_max: float = 1.1

@export_multiline var description: String = ""

# Helper function to get the actual stream to play
func get_playback_stream() -> AudioStream:
	if variations.size() > 0:
		return variations.pick_random()
	return stream
