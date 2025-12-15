extends Area2D

@export var speed_reduction: float = 0.5
@export var jump_reduction: float = 0.2

var player_in_area: Node2D = null
var logger: Logger = NoLogger.new()

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	logger.log("Quicksand ready - monitoring: " + str(monitoring))
	logger.log("Collision layer: " + str(collision_layer))
	logger.log("Collision mask: " + str(collision_mask))

func _physics_process(_delta: float) -> void:
	# Continuously apply slow effect while player is in area
	if player_in_area:
		if player_in_area.has_method("set_speed_multiplier"):
			player_in_area.set_speed_multiplier(speed_reduction)
		
		if player_in_area.has_method("set_jump_multiplier"):
			player_in_area.set_jump_multiplier(jump_reduction)
		
		# Disable dash
		if "can_dash" in player_in_area:
			player_in_area.can_dash = false

func _on_body_entered(body: Node2D) -> void:
	logger.log("Body entered: " + str(body.name))
	if body.has_method("set_speed_multiplier"):
		player_in_area = body
		
		if "can_dash" in body:
			body.can_dash = false
			logger.log("Dash disabled")
		
		logger.log("Player entered quicksand")

func _on_body_exited(body: Node2D) -> void:
	logger.log("Body exited: " + str(body.name))
	if body == player_in_area:
		# Use call_deferred to reset after a frame, giving other quicksands chance to apply their effect
		call_deferred("_reset_player", body)

func _reset_player(body: Node2D) -> void:
	# Only reset if player is still not in this area
	if body == player_in_area and not body in get_overlapping_bodies():
		if body.has_method("set_speed_multiplier"):
			body.set_speed_multiplier(1.0)
			logger.log("Speed multiplier reset to 1.0")
		
		if body.has_method("set_jump_multiplier"):
			body.set_jump_multiplier(1.0)
			logger.log("Jump multiplier reset to 1.0")
		
		# Restore dash
		if "can_dash" in body:
			body.can_dash = true
			logger.log("Dash restored")
		
		player_in_area = null
