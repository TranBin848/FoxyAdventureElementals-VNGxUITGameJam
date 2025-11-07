extends Node2D

@onready var detect_area: Area2D = $DetectArea
@onready var timer: Timer = $Timer
@onready var hit_area_2d: CollisionShape2D = $HitArea2D/CollisionShape2D
@onready var animated_sprite_2d: AnimatedSprite2D = $AnimatedSprite2D

var is_activated: bool = false

func _on_detect_area_body_entered(body: Node2D) -> void:
	if not is_activated: 
		is_activated = true
		start_timer(0.5)

func start_timer(duration: float) -> void:
	timer.one_shot = true
	timer.wait_time = duration
	timer.start()

func _on_timer_timeout() -> void:
	if is_activated:
		hit_area_2d.disabled = false
		is_activated = false
		animated_sprite_2d.play("activate")
		start_timer(2)
	else:
		hit_area_2d.disabled = true
		animated_sprite_2d.play("deactivate")
	
