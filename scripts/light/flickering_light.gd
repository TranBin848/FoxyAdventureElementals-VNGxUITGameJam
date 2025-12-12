extends PointLight2D

@export_category("Flicker Settings")
@export var noise_speed: float = 5.0
@export var energy_variation: float = 0.3 # How much the light dims/brightens
@export var size_variation: float = 0.1   # How much the light grows/shrinks

var noise = FastNoiseLite.new()
var time_passed: float = 0.0
var base_energy: float
var base_scale: float

func _ready() -> void:
	# Store the initial values you set in the Inspector
	base_energy = energy
	base_scale = texture_scale
	
	# Configure the noise for a nice fire look
	noise.seed = randi()
	noise.frequency = 0.1

func _process(delta: float) -> void:
	time_passed += delta * noise_speed
	
	# Get a smooth random number between -1 and 1
	var noise_value = noise.get_noise_1d(time_passed)
	
	# Apply flicker to energy (Brightness)
	energy = base_energy + (noise_value * energy_variation)
	
	# Apply flicker to scale (Breathing effect)
	# We multiply by 0.5 so the size change is subtle compared to brightness
	texture_scale = base_scale + (noise_value * size_variation)
