extends EnemyState
@export var attack_frames: int = 6
var attack_time: float = 0
var default_animation_speed: float = 1.0
var animation_speed: float = 1.0

func _enter() -> void:
	obj.change_animation("attack")
	obj.velocity.x = 0
	#obj.velocity.x = obj.attack_speed * obj.direction
	calculate_attack_time()
	calculate_animation_speed()
	obj.enable_wind()
	#init_wind()
	#obj.enable_hit_area()
	timer = attack_time

func calculate_attack_time() -> void:
	attack_time = obj.sight / obj.attack_speed

func calculate_animation_speed() -> void:
	default_animation_speed = obj.animated_sprite.speed_scale
	animation_speed = attack_frames / attack_time
	pass

#
		##obj.spear_collision_shape.size.x = 0

func _update(_delta: float) -> void:
	if obj.is_frozen: return
	#obj.animated_sprite.speed_scale = animation_speed
	if update_timer(_delta):
		change_state(fsm.states.idle)
	update_wind()
#
func update_wind() -> void:
	if obj.wind != null:
		#obj.spear_collision_shape.size.x = obj.sight * (1.0 - timer / attack_time)
		#obj.spear_collision.position.x = obj.spear_collision_shape.size.x * 0.5
		obj.wind.position.x = obj.sight * (1.0 - timer / attack_time)
		print (obj.wind)
	pass

func _exit() -> void:
	#obj.velocity.x = 0
	#obj.disable_hit_area()
	obj.disable_wind()
	#obj.animated_sprite.speed_scale = default_animation_speed
