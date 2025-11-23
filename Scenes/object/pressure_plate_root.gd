extends Node2D
class_name PressurePlateRoot

# Export parameter để link với door trong editor
@export var connected_door: WoodenDoorRoot = null
@export var connected_doors: Array[WoodenDoorRoot] = []

# Get child components
@onready var area: Area2D = $Area2D

# Internal state
var is_activated: bool = false
var bodies_on_plate: Array[Node2D] = []

# Signals
signal plate_activated
signal plate_deactivated

func _ready():
	# Connect Area2D signals from child
	if area:
		area.body_entered.connect(_on_body_entered)
		area.body_exited.connect(_on_body_exited)
		
		# Setup collision detection
		area.monitoring = true
		area.monitorable = true
		area.collision_mask = 0b11111111  # Monitor all layers
	
	print("PressurePlateRoot ready - connected to ", connected_doors.size(), " doors")
	
	# Validate connected doors
	if connected_door != null and connected_door not in connected_doors:
		connected_doors.append(connected_door)

func _on_body_entered(body: Node2D):
	print("Body entered pressure plate: ", body, " | Type: ", body.get_class())
	
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
	# Get AnimatedSprite2D and play animations directly
	var animated_sprite = $AnimatedSprite2D as AnimatedSprite2D
	if animated_sprite:
		if is_activated:
			animated_sprite.play("pressed")
		else:
			animated_sprite.play("unpressed")
	else:
		print("AnimatedSprite2D not found at AnimatedSprite2D")

# Method để manually connect door từ code (nếu cần)
func connect_door(door: WoodenDoorRoot):
	if door and door not in connected_doors:
		connected_doors.append(door)
		print("Connected door: ", door.name)

func disconnect_door(door: WoodenDoorRoot):
	if door in connected_doors:
		connected_doors.erase(door)
		print("Disconnected door: ", door.name)
