extends Area2D
class_name PressurePlate

# Export parameter để link với door trong editor
@export var connected_door: WoodenDoor = null
@export var connected_doors: Array[WoodenDoor] = []

# Signals
signal plate_activated
signal plate_deactivated

# Internal state
var is_activated: bool = false
var bodies_on_plate: Array[Node2D] = []

# Visual feedback
@onready var sprite: AnimatedSprite2D = $"../AnimatedSprite2D"

func _ready():
	# Connect Area2D signals
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	
	# Setup collision detection
	monitoring = true
	monitorable = true
	collision_mask = 0b11111111  # Monitor all layers
	
	print("PressurePlate ready - connected to ", connected_doors.size(), " doors")
	
	# Validate connected doors
	if connected_door != null and connected_door not in connected_doors:
		connected_doors.append(connected_door)

func _on_body_entered(body: Node2D):
	# Check if it's a valid body (Player, enemies, etc.)
	if body is Player or body is CharacterBody2D or body.is_in_group("activatable"):
		if body not in bodies_on_plate:
			bodies_on_plate.append(body)
			print("Added body to plate: ", body.name)
			
		# Activate plate if not already active
		if not is_activated:
			_activate_plate()

func _on_body_exited(body: Node2D):
	print("Body exited pressure plate: ", body, " | Type: ", body.get_class())
	
	if body in bodies_on_plate:
		bodies_on_plate.erase(body)
		print("Removed body from plate: ", body.name)
		
		# Deactivate if no bodies left
		if bodies_on_plate.is_empty() and is_activated:
			_deactivate_plate()

func _activate_plate():
	if is_activated:
		return
		
	is_activated = true
	print("Pressure plate ACTIVATED")
	
	# Visual feedback
	_update_visual()
	
	# Open connected doors
	for door in connected_doors:
		if is_instance_valid(door):
			door.open_door()
	
	# Emit signal for other systems
	plate_activated.emit()

func _deactivate_plate():
	if not is_activated:
		return
		
	is_activated = false
	print("Pressure plate DEACTIVATED")
	
	# Visual feedback
	_update_visual()
	
	# Close connected doors after 3 second delay
	await get_tree().create_timer(3.0).timeout
	for door in connected_doors:
		if is_instance_valid(door):
			door.close_door()
	
	# Emit signal for other systems
	plate_deactivated.emit()

func _update_visual():
	# Get AnimatedSprite2D using relative path from Area2D
	var animated_sprite = $AnimatedSprite2D as AnimatedSprite2D
	if animated_sprite:
		if is_activated:
			animated_sprite.play("pressed")
		else:
			animated_sprite.play("idle")
	else:
		print("AnimatedSprite2D not found as child of Area2D")

# Method để manually connect door từ code (nếu cần)
func connect_door(door: WoodenDoor):
	if door and door not in connected_doors:
		connected_doors.append(door)
		print("Connected door: ", door.name)

func disconnect_door(door: WoodenDoor):
	if door in connected_doors:
		connected_doors.erase(door)
		print("Disconnected door: ", door.name)
