extends Area2D
class_name AmbienceArea2D

@export var ambience_music_id: String = ""
@export var volume_db: float = 0.0
@export var fade_in: float = 0.0

var is_player_inside: bool = false
var previous_music_id: String = ""
var previous_volume_db: float = 0.0

func _ready() -> void:
	if not AudioManager:
		push_error("AudioManager not found! Make sure it's in autoload.")
		return
	
	collision_mask = 2
	
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

# called when body entered
func _on_body_entered(body):
	if is_player_inside:
		return
	is_player_inside = true
	
	if AudioManager:
		previous_music_id = AudioManager.get_current_music_id()
		previous_volume_db = AudioManager.music_player.volume_db
		
	_switch_music_id(ambience_music_id, volume_db, fade_in)
	print("Player entered area - Switched to ambience music: ", ambience_music_id)

func _on_body_exited(body):
	if not is_player_inside:
		return
	is_player_inside = false
	_switch_music_id(previous_music_id, previous_volume_db, fade_in)
	print("Player exited area - Switched to previous music: ", previous_music_id)
	
func _switch_music_id(music_id: String, volume_db: float, fade_in: float) -> void:
	if not AudioManager:
		return
	AudioManager.play_music(music_id, volume_db, fade_in)
