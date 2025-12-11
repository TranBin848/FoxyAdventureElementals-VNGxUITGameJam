class_name AudioDatabase
extends Resource

## Database contains all audio clips in the game
## Audio engineer only needs to add AudioClip resources here, no code needed!

var _clips: Array[AudioClip] = []
var _clip_map: Dictionary = {}

@export var clips: Array[AudioClip] = []:
	set(value):
		_clips = value
		_rebuild_map()
	get:
		return _clips

func _init():
	_rebuild_map()

func _rebuild_map() -> void:
	_clip_map.clear()
	for clip in _clips:
		if clip == null:
			continue
		if clip.clip_id.is_empty():
			continue
		if _clip_map.has(clip.clip_id):
			push_warning("Duplicate audio clip ID detected: " + clip.clip_id)
		_clip_map[clip.clip_id] = clip

## Get clip by ID
func get_clip(clip_id: String) -> AudioClip:
	if not _clip_map.has(clip_id):
		push_warning("Audio clip does not exist: " + clip_id)
		return null
	return _clip_map[clip_id] as AudioClip


## Add clip to database (can be called from editor or code)
func add_clip(clip: AudioClip) -> void:
	if clip == null or clip.clip_id.is_empty():
		push_error("AudioClip is invalid!")
		return

	var replaced := false
	for i in range(_clips.size()):
		var existing: AudioClip = _clips[i]
		if existing == null:
			continue
		if existing.clip_id == clip.clip_id:
			_clips[i] = clip
			replaced = true
			break

	if not replaced:
		_clips.append(clip)

	_clip_map[clip.clip_id] = clip


## Check if clip exists
func has_clip(clip_id: String) -> bool:
	return _clip_map.has(clip_id)


## Get all clip IDs
func get_all_clip_ids() -> Array:
	return _clip_map.keys()
