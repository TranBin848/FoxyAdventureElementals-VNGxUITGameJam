extends StaticBody2D
class_name UnstablePlatform

# We removed "is_unstable" because this script defines that behavior exclusively.
@export var reset_grace_period: float = 1.0 
@onready var collision_shape: CollisionShape2D = $CollisionShape2D

var is_triggered: bool = false

# Ensure this signal is connected from your Area2D in the Unstable Platform scene
func _on_area_2d_body_entered(_body: Node2D) -> void:
	# We only check if it is already triggered.
	if is_triggered:
		return
	
	_start_sequence()

func _start_sequence() -> void:
	is_triggered = true
	
	# 1. Fade out
	var tween = create_tween()
	tween.tween_property(self, "modulate:a", 0.0, 1.0)
	await tween.finished
	
	# 2. Disable collision
	collision_shape.set_deferred("disabled", true)
	
	# 3. Wait for respawn (5 seconds)
	await get_tree().create_timer(5.0).timeout
	
	# Safety check: ensure object wasn't deleted during the wait
	if not is_instance_valid(self): return
	_reset_platform()

func _reset_platform() -> void:
	# 4. Re-enable collision immediately (so player can land)
	collision_shape.set_deferred("disabled", false)
	
	# 5. Fade in
	var tween = create_tween()
	tween.tween_property(self, "modulate:a", 1.0, 0.5)
	await tween.finished
	
	# 6. Grace Period
	# Platform is solid, visible, but will not trigger the fall sequence yet
	if reset_grace_period > 0:
		await get_tree().create_timer(reset_grace_period).timeout
	
	# 7. Finally allow detection again
	is_triggered = false
