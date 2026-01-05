extends StaticBody2D

@onready var collision_shape: CollisionShape2D = $CollisionShape2D
@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D

var timer: Timer
var trap_is_active = false # Renamed to avoid conflict with built-in 'is_visible'

func _ready() -> void:
	timer = Timer.new()
	timer.wait_time = 6.0 
	timer.one_shot = true # Set to One Shot so we can control exactly when it restarts
	timer.timeout.connect(_on_timer_timeout)
	add_child(timer)
	
	# Initial State: Hidden/Safe
	trap_is_active = false
	collision_shape.disabled = true
	animated_sprite.play("end") # Ensure it looks closed visually
	animated_sprite.frame = animated_sprite.sprite_frames.get_frame_count("end") - 1 # Jump to last frame of "end"
	
	print("🔄 Trap init - waiting for first trigger...")
	timer.start() # Starts the first cooldown cycle

func _on_timer_timeout() -> void:
	if trap_is_active:
		_deactivate_trap()
	else:
		_activate_trap()

func _activate_trap() -> void:
	# 1. Play the warning/opening animation
	animated_sprite.play("start")
	
	# 2. Wait for animation to finish
	await animated_sprite.animation_finished
	
	# 3. Enable danger
	trap_is_active = true
	collision_shape.set_deferred("disabled", false)
	print("⚠️ Trap ACTIVE")
	
	# 4. Restart timer (How long the trap stays active)
	timer.start() 

func _deactivate_trap() -> void:
	# 1. Disable danger immediately
	trap_is_active = false
	collision_shape.set_deferred("disabled", true)
	
	# 2. Play closing animation
	animated_sprite.play("end")
	
	# 3. Wait for animation to finish
	await animated_sprite.animation_finished
	print("💤 Trap HIDDEN")
	
	# 4. Restart timer (How long the trap stays hidden)
	timer.start()
