extends GPUParticles2D

# --- WIND SETTINGS ---
@export_group("Wind Settings")
@export var wind_force: float = 0.2  # Speed boost when in wind
@export var base_amount: int = 20

# --- AMBIENCE SETTINGS ---
@export_group("Ambience Settings")
@export var ambience_id: String = ""
@export var volume_db: float = 0.0
@export var fade_in: float = 1.0
@export var fade_out: float = 1.0

# --- INTERNAL VARIABLES ---
var player_in_wind: Node2D = null
var wind_direction: Vector2 = Vector2.ZERO
var logger: Logger = ConsoleLogger.new()

# Ambience state
var previous_ambience_id: String = ""

func _ready():
	# 0. Safety Check
	if not AudioManager:
		push_error("AudioManager not found! Make sure it's in autoload.")
	
	# 1. Set initial state
	_update_particles(SettingsManager.particle_quality)
	
	# 2. Listen for changes from the menu
	SettingsManager.particle_quality_changed.connect(_update_particles)
	
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
	
	# 1. Handle Wind Physics
	if body.has_method("set_speed_multiplier"):
		player_in_wind = body
		logger.log("Player entered wind area - applying wind force: " + str(wind_force))

	# 2. Handle Ambience
	# We check "is Player" specifically for audio to avoid triggering music for NPCs/enemies
	if body is Player:
		if AudioManager and ambience_id != "":
			previous_ambience_id = AudioManager.get_current_ambience_id()
			AudioManager.play_ambience(ambience_id, volume_db, fade_in)
			logger.log("SandStorm Ambience Started: " + ambience_id)

func _on_body_exited(body: Node2D):
	logger.log("Body exited: " + str(body.name))
	
	# 1. Handle Wind Physics
	if body == player_in_wind:
		if player_in_wind.has_method("set_speed_multiplier"):
			player_in_wind.set_speed_multiplier(1.0)
			logger.log("Player exited wind area. Speed reset to 1.0")
		player_in_wind = null

	# 2. Handle Ambience
	if body is Player:
		if AudioManager:
			# Restore previous ambience if it existed
			if previous_ambience_id != "":
				AudioManager.play_ambience(previous_ambience_id, 0.0, fade_in)
				logger.log("Restored previous ambience: " + previous_ambience_id)
			else:
				# If there was no previous ambience, you might want to stop the current one
				# or define a default behavior. 
				pass

func _update_particles(quality_level: int):
	# Calculate target amount
	var new_amount = int(base_amount * (float(quality_level) / 3.0))

	# CASE 1: Turn OFF (Quality is 0)
	if new_amount <= 0:
		emitting = false
		return

	# CASE 2: Turn ON (Quality > 0)
	emitting = true

	# Only change 'amount' if the number is different.
	if amount != new_amount:
		amount = new_amount
