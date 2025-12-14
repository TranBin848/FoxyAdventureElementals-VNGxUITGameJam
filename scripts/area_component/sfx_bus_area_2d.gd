extends Area2D
class_name SFXBusArea2D

@export var target_bus_name: String = ""
var previous_bus_name: String = "SFX"

var is_player_inside: bool = false

func _ready() -> void:
	if not AudioManager:
		push_error("AudioManager not found! Make sure it's in autoload.")
		return
	
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

# called when body entered
func _on_body_entered(body):
	if is_player_inside:
		return
	is_player_inside = true
	
	if AudioManager:
		previous_bus_name = AudioManager.get_current_sfx_bus_name()
		
	_switch_sfx_bus(target_bus_name)
	print("Player entered area - Switched to bus: ", target_bus_name)

func _on_body_exited(body):
	if not is_player_inside:
		return
	is_player_inside = false
	_switch_sfx_bus(previous_bus_name)
	print("Player exited area - Switched to previous bus: ", previous_bus_name)
	
func _switch_sfx_bus(bus_name: String) -> void:
	if not AudioManager:
		return
	AudioManager.switch_sfx_bus(bus_name)
