extends StaticBody2D
class_name WoodenDoor

# Door states
enum DoorState { CLOSED, OPENING, OPEN, CLOSING }

# Export parameters
@export var is_initially_open: bool = false
@export var auto_close_delay: float = 0.0  # 0 = không tự động đóng
@export var open_sound: AudioStream = null
@export var close_sound: AudioStream = null

# Internal state
var current_state: DoorState = DoorState.CLOSED
var auto_close_timer: Timer = null

# Nodes
@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var collision_shape: CollisionShape2D = $CollisionShape2D
@onready var audio_player: AudioStreamPlayer2D = $AudioStreamPlayer2D

# Signals
signal door_opened
signal door_closed
signal door_opening
signal door_closing

func _ready():
	# Setup initial state
	if is_initially_open:
		current_state = DoorState.OPEN
		_set_door_open_visual()
		_set_collision_disabled(true)
	else:
		current_state = DoorState.CLOSED
		_set_door_closed_visual()
		_set_collision_disabled(false)
	
	# Setup auto-close timer if needed
	if auto_close_delay > 0:
		auto_close_timer = Timer.new()
		auto_close_timer.wait_time = auto_close_delay
		auto_close_timer.one_shot = true
		auto_close_timer.timeout.connect(_auto_close_door)
		add_child(auto_close_timer)
	
	print("WoodenDoor ready - state: ", DoorState.keys()[current_state])

func open_door():
	if current_state == DoorState.OPEN or current_state == DoorState.OPENING:
		return
	
	print("Opening door: ", name)
	current_state = DoorState.OPENING
	door_opening.emit()
	
	# Play sound
	if open_sound and audio_player:
		audio_player.stream = open_sound
		audio_player.play()
	
	# Play open animation using relative path from StaticBody2D
	if sprite:
		sprite.play("open")
		await get_tree().create_timer(0.5).timeout  # Wait for animation
	else:
		print("AnimatedSprite2D not found as child of StaticBody2D")
		await _simple_open_animation()
	
	# Set final state
	current_state = DoorState.OPEN
	_set_door_open_visual()
	_set_collision_disabled(true)
	door_opened.emit()
	
	# Start auto-close timer if enabled
	if auto_close_timer:
		auto_close_timer.start()

func close_door():
	if current_state == DoorState.CLOSED or current_state == DoorState.CLOSING:
		return
	
	print("Closing door: ", name)
	current_state = DoorState.CLOSING
	door_closing.emit()
	
	# Stop auto-close timer
	if auto_close_timer:
		auto_close_timer.stop()
	
	# Play sound
	if close_sound and audio_player:
		audio_player.stream = close_sound
		audio_player.play()
	
	# Play close animation using relative path from StaticBody2D
	if sprite:
		sprite.play("close")
		await get_tree().create_timer(0.5).timeout  # Wait for animation
	else:
		print("AnimatedSprite2D not found as child of StaticBody2D")
		await _simple_close_animation()
	
	# Set final state
	current_state = DoorState.CLOSED
	_set_door_closed_visual()
	_set_collision_disabled(false)
	door_closed.emit()

func toggle_door():
	if current_state == DoorState.CLOSED:
		open_door()
	elif current_state == DoorState.OPEN:
		close_door()

func _auto_close_door():
	if current_state == DoorState.OPEN:
		close_door()

func _set_collision_disabled(disabled: bool):
	if collision_shape:
		collision_shape.disabled = disabled

func _set_door_open_visual():
	if sprite:
		sprite.play("open")
		sprite.modulate = Color(1, 1, 1, 0.7)  # Make slightly transparent

func _set_door_closed_visual():
	if sprite:
		sprite.play("close")
		sprite.modulate = Color.WHITE

func _simple_open_animation():
	# Simple tween animation as fallback
	var tween = create_tween()
	tween.tween_property(self, "modulate:a", 0.5, 0.3)
	await tween.finished

func _simple_close_animation():
	# Simple tween animation as fallback
	var tween = create_tween()
	tween.tween_property(self, "modulate:a", 1.0, 0.3)
	await tween.finished

# Method để check state từ bên ngoài
func is_open() -> bool:
	return current_state == DoorState.OPEN

func is_closed() -> bool:
	return current_state == DoorState.CLOSED

func is_moving() -> bool:
	return current_state == DoorState.OPENING or current_state == DoorState.CLOSING
