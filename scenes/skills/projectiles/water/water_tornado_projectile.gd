extends ProjectileBase
class_name WaterTornadoProjectile

@export var tornado_duration: float = 3.0
@export var knockback_force: float = 300.0
@export var knockback_upward_bias: float = 0.2  # Slight upward lift
@onready var explosion_area: Area2D = $ExplosionArea	
@export var explosion_anim: String = "WaterTornado_End"

@onready var duration_timer: Timer = Timer.new()
# --- State ---
var exploding: bool = false
var ending: bool = false
var tornado_center: Vector2  # Store tornado center position

func _ready() -> void:
	duration_timer.one_shot = true
	duration_timer.wait_time = tornado_duration
	duration_timer.timeout.connect(_start_ending_sequence)
	add_child(duration_timer)

func _physics_process(delta: float) -> void:
	if exploding:
		return
	
	super._physics_process(delta)
	
func _start_ending_sequence() -> void:
	if ending:
		return
		
	ending = true
	tornado_center = global_position  # Store center before ending
	
	duration_timer.stop()
	set_physics_process(false) 
	
	$AnimatedSprite2D.play(explosion_anim)
	
	$AnimatedSprite2D.connect(
		"animation_finished",
		Callable(self, "_on_animation_finished"),
		CONNECT_ONE_SHOT
	)

func _on_hit_area_2d_hitted(area: Variant) -> void:
	_trigger_explosion()
		

func _on_body_entered(body: Node2D) -> void:
	if $AnimatedSprite2D.animation != "WaterTornado_End":
		_start_ending_sequence() 


func _trigger_explosion() -> void:
	if exploding:
		return
	
	exploding = true
	tornado_center = global_position  # Store initial position
	
	duration_timer.start()
	
	var overlaps = explosion_area.get_overlapping_bodies()
	print(overlaps)
	for b in overlaps:
		if b is EnemyCharacter:
			affected_enemies.append(b)
			b.enter_skill(tornado_center)


func _on_animation_finished() -> void:
	for e in affected_enemies:
		if e and is_instance_valid(e) and e.is_inside_tree():
			e.exit_skill()

			# Calculate radial knockback from tornado center
			var direction = (e.global_position - tornado_center).normalized()
			
			# Create knockback vector with upward spiral effect
			var knockback_vector = Vector2(
				direction.x * knockback_force,
				(direction.y * knockback_force) - (knockback_force * knockback_upward_bias)
			)
			
			e.apply_knockback(knockback_vector)
	
	queue_free()

func _on_explosion_area_body_entered(body: Node2D) -> void:
	if ending:
		return
		
	if exploding and body is EnemyCharacter:
		if not affected_enemies.has(body):
			affected_enemies.append(body)
			body.enter_skill(tornado_center)  # Use stored center position
