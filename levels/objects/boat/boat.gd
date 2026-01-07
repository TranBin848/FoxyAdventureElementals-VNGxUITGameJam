extends Node2D

@export_file("*.tscn") var target_stage: String = ""
@export var target_door: String = "Door"

@onready var animated_sprite_2d: AnimatedSprite2D = $BoatFrame/AnimatedSprite2D
@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var fade_layer: CanvasLayer = get_tree().get_first_node_in_group("FadeLayer")

var is_busy: bool = false
@export var interactable: bool = false
func _on_interactive_area_2d_interacted() -> void:
	if interactable == false:
		return
	
	if is_busy:
		return
		
	is_busy = true
	await sail_boat_and_transition()
	is_busy = false

func sail_boat_and_transition() -> void:
	if not animation_player:
		push_error(name + ": No animation player found!")
		return

	animation_player.play("sail right")
	Dialogic.start("sail_boat")
	
	await get_tree().create_timer(2.0).timeout
	
	# Fade Out
	if fade_layer:
		await fade_layer.fade_out()

	# Transition Logic
	if GameManager.current_stage.scene_file_path == target_stage:
		# Same stage: Move player only
		var door_node = GameManager.current_stage.find_child(target_door)
		if door_node and GameManager.player:
			GameManager.player.global_position = door_node.global_position
	else:
		# Different stage: Change scene
		GameManager.change_stage(target_stage, target_door)
	
	# Fade In
	if fade_layer:
		await fade_layer.fade_in()
