extends Area2D

# Signal to detect when a body enters or exits the quicksand area
signal body_entered_quicksand(body)
signal body_exited_quicksand(body)

# Percentage to reduce the player's speed
const SPEED_REDUCTION_PERCENTAGE = 0.5

func _ready():
	# Ensure Area2D is monitoring bodies
	monitoring = true
	monitorable = true
	
	# Set collision layers - monitor all layers for debugging
	collision_mask = 0b11111111  # Monitor all 8 layers temporarily for debugging
	
	# Connect signals for body entered and exited
	self.connect("body_entered", Callable(self, "_on_body_entered"))
	self.connect("body_exited", Callable(self, "_on_body_exited"))
	
	print("Quicksand ready - monitoring: ", monitoring, " | collision_layer: ", collision_layer, " | collision_mask: ", collision_mask)

func _on_body_entered(body):
	print("Entered quicksand: ", body, " | Type: ", body.get_class())
	if body is Player:  # Check if body is specifically a Player
		if body.has_method("set_speed_multiplier"):
			print("Applying speed reduction to Player: ", body)
			body.set_speed_multiplier(SPEED_REDUCTION_PERCENTAGE)
		else:
			print("Player does not have set_speed_multiplier method: ", body)
	else:
		print("Ignored non-player body: ", body)

func _on_body_exited(body):
	print("Exited quicksand: ", body, " | Type: ", body.get_class())
	if body is Player:  # Check if body is specifically a Player
		if body.has_method("set_speed_multiplier"):
			print("Resetting speed for Player: ", body)
			body.set_speed_multiplier(1.0)  # Reset speed to normal
		else:
			print("Player does not have set_speed_multiplier method: ", body)
	else:
		print("Ignored non-player body: ", body)
