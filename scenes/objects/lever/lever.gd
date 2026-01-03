extends Area2D
class_name Lever

enum LeverType {ON_GROUND, ON_WALL_LEFT, ON_WALL_RIGHT} 

@onready var on_ground_sprite: AnimatedSprite2D = $"AnimatedSprites/OnGround"
@onready var on_wall_left_sprite: AnimatedSprite2D = $"AnimatedSprites/OnWallLeft"
@onready var on_wall_right_sprite: AnimatedSprite2D = $"AnimatedSprites/OnWallRight"
@onready var animated_sprite: AnimatedSprite2D = null

@export var linked_door: Node2D = null
@export var type: LeverType = LeverType.ON_GROUND

var is_activated: bool = false
var player_in_area: bool = false
var logger: Logger = ConsoleLogger.new()

func _ready():
	on_ground_sprite.visible = false
	on_wall_left_sprite.visible = false
	on_wall_right_sprite.visible = false
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	set_process_unhandled_input(false)
	match type:
		LeverType.ON_GROUND:
			on_ground_sprite.visible = true
			animated_sprite = $AnimatedSprites/OnGround

		LeverType.ON_WALL_LEFT:
			on_wall_left_sprite.visible = true
			animated_sprite = $AnimatedSprites/OnWallLeft

		LeverType.ON_WALL_RIGHT:
			on_wall_right_sprite.visible = true
			animated_sprite = $AnimatedSprites/OnWallRight

		_:
			push_warning("Unknown LeverType")
	logger.log("Lever ready")

func _unhandled_input(event):
	logger.log("Unhandled input received. Player in area: " + str(player_in_area))
	if event.is_action_pressed("interact"):
		logger.log("Interact pressed")
		toggle()
		get_viewport().set_input_as_handled()

func _on_body_entered(body: Node2D):
	logger.log("Body entered: " + str(body.name))
	if body.name == "Player" or body.has_method("set_speed_multiplier"):
		player_in_area = true
		set_process_unhandled_input(true)
		logger.log("Player entered lever area - input enabled")

func _on_body_exited(body: Node2D):
	logger.log("Body exited: " + str(body.name))
	if body.name == "Player" or body.has_method("set_speed_multiplier"):
		player_in_area = false
		set_process_unhandled_input(false)
		logger.log("Player exited lever area - input disabled")

func toggle():
	logger.log("Toggle lever called. Player in area: " + str(player_in_area))
	if not player_in_area:
		logger.log("Cannot toggle - player not in area")
		return
	
	is_activated = !is_activated
	logger.log("Lever toggled. Is activated: " + str(is_activated))
	
	if is_activated:
		animated_sprite.play("active")
		if linked_door:
			linked_door.open_door()
			logger.log("Door opened")
	else:
		animated_sprite.play("inactive")
		if linked_door:
			linked_door.close_door()
			logger.log("Door closed")
