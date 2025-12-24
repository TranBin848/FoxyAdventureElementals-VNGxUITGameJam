extends Area2D
class_name AmbienceArea2D

@export var ambience_id: String = ""
@export var volume_db: float = 0.0
@export var fade_in: float = 1.0
@export var fade_out: float = 1.0

var is_player_inside: bool = false
var previous_ambience_id: String = ""

func _ready() -> void:
	if not AudioManager:
		push_error("AudioManager not found! Make sure it's in autoload.")
		return
	
	collision_mask = 2
	
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

# Called when body entered
func _on_body_entered(body: Node2D) -> void:
	if not body is Player:
		return
	
	if is_player_inside:
		return
	
	is_player_inside = true
	
	if AudioManager:
		# Store previous ambience to restore later
		previous_ambience_id = AudioManager.get_current_ambience_id()
		
		# Play new ambience alongside music
		if ambience_id != "":
			AudioManager.play_ambience(ambience_id, volume_db, fade_in)
			print("Player entered area - Playing ambience: ", ambience_id)

func _on_body_exited(body: Node2D) -> void:
	if not body is Player:
		return
	
	if not is_player_inside:
		return
	
	is_player_inside = false
	
	if AudioManager:
		# Stop current ambience
		print("Player exited area - Stopped ambience: ", ambience_id)
		
		# Optionally restore previous ambience if it existed
		if previous_ambience_id != "":
			AudioManager.play_ambience(previous_ambience_id, 0.0, fade_in)
			print("Restored previous ambience: ", previous_ambience_id)
