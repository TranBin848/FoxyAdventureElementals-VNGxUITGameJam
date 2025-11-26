extends EnemyState
@export var attack_frames: int = 6
var attack_time: float = 0
var default_animation_speed: float = 1.0
var animation_speed: float = 1.0

func _enter() -> void:
	obj.change_animation("attack")
	obj.velocity.x = 0
	calculate_attack_time()
	calculate_animation_speed()
	init_spear_collision()
	timer = attack_time

func calculate_attack_time() -> void:
	attack_time = obj.sight / obj.attack_speed

func calculate_animation_speed() -> void:
	default_animation_speed = obj.animated_sprite.speed_scale
	animation_speed = attack_frames / attack_time
	pass

func init_spear_collision() -> void:
	if obj.spear_collision_shape != null:
		obj.spear_collision.disabled = false
		obj.spear_collision_shape.size.x = 0

func _update(_delta: float) -> void:
	obj.animated_sprite.speed_scale = animation_speed
	if update_timer(_delta):
		change_state(fsm.states.idle)
	update_spear_collision()

func update_spear_collision() -> void:
	if obj.spear_collision_shape != null:
		obj.spear_collision_shape.size.x = obj.sight * (1.0 - timer / attack_time)
		obj.spear_collision.position.x = obj.spear_collision_shape.size.x * 0.5
		print (obj.spear_collision.position.x)
	pass

func _exit() -> void:
	if obj.spear_collision != null:
		obj.spear_collision.disabled = true
	obj.animated_sprite.speed_scale = default_animation_speed
