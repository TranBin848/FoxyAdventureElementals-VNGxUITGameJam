extends GPUParticles2D

@export var wind_force: float = 0.2  # Speed boost when in wind

var player_in_wind: Node2D = null
var wind_direction: Vector2 = Vector2.ZERO
var logger: Logger = ConsoleLogger.new()

func _ready():
	# Get wind direction from particle gravity
	if process_material and process_material is ParticleProcessMaterial:
		var gravity = process_material.gravity
		wind_direction = Vector2(gravity.x, gravity.y).normalized()
		logger.log("Wind direction: " + str(wind_direction))
	
	# Get existing Area2D node
	var area = $Area2D
	if area:
		area.body_entered.connect(_on_body_entered)
		area.body_exited.connect(_on_body_exited)
		logger.log("Sand storm ready. Area2D found and connected")
	else:
		logger.log("ERROR: Area2D not found!")

func _physics_process(_delta: float):
	if player_in_wind and "velocity" in player_in_wind:
		var player_velocity = player_in_wind.velocity
		
		# Only apply wind effect if player is moving
		if player_velocity.length() > 10:
			var player_dir = player_velocity.normalized()
			var alignment = player_dir.dot(wind_direction)
			
			var speed_mult = 1.0
			
			if alignment > 0.5:  # Moving with wind (same direction)
				speed_mult = 1.0 + wind_force
			elif alignment < -0.5:  # Moving against wind
				speed_mult = 1.0 - wind_force * 0.5
			else:  # Moving perpendicular to wind
				speed_mult = 1.0
			
			if player_in_wind.has_method("set_speed_multiplier"):
				player_in_wind.set_speed_multiplier(speed_mult)

func _on_body_entered(body: Node2D):
	logger.log("Body entered: " + str(body.name))
	if body.has_method("set_speed_multiplier"):
		player_in_wind = body
		logger.log("Player entered wind area - applying wind force: " + str(wind_force))

func _on_body_exited(body: Node2D):
	logger.log("Body exited: " + str(body.name))
	if body == player_in_wind:
		if player_in_wind.has_method("set_speed_multiplier"):
			player_in_wind.set_speed_multiplier(1.0)
			logger.log("Player exited wind area. Speed reset to 1.0")
		player_in_wind = null
