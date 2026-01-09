extends EnemyCharacter

@export var turn_around_delay: float = 2

var wind: Node2D
var wind_hit_area_collision: CollisionShape2D
var wind_animated_sprite_2d: AnimatedSprite2D
#var wind_collision: CollisionShape2D
#var spear_collision_shape: RectangleShape2D
var turn_around_delay_timer: float = 0

func _ready() -> void:
	super._ready()
	fsm = FSM.new(self, $States, $States/Idle)
	_init_wind()
	reset_turn_around_delay_timer()

func _process(delta: float) -> void:
	update_turn_around_delay_timer(delta)
	#if animated_sprite != null:
		#print(animated_sprite.speed_scale)

func _init_wind() -> void:
	#if has_node("Direction/SpearHitArea2D"):
		#spear_hit_area_2d = $Direction/SpearHitArea2D
		#spear_hit_area_2d.damage = attack_damage
		#spear_hit_area_2d.elemental_type = elemental_type
	#
	#if has_node("Direction/SpearHitArea2D/CollisionShape2D"):
		#if $Direction/SpearHitArea2D/CollisionShape2D is CollisionShape2D:
			#spear_collision = $Direction/SpearHitArea2D/CollisionShape2D
	#if spear_collision != null and spear_collision.shape is RectangleShape2D:
		#spear_collision_shape = (spear_collision.shape as RectangleShape2D)
	if has_node("Direction/Wind"):
		wind = $Direction/Wind
		if has_node("Direction/Wind/WindHitArea2D"):
			(($Direction/Wind/WindHitArea2D) as HitArea2D).elemental_type = elemental_type
			(($Direction/Wind/WindHitArea2D) as HitArea2D).damage = attack_damage
			if has_node("Direction/Wind/WindHitArea2D/CollisionShape2D"):
				wind_hit_area_collision = $Direction/Wind/WindHitArea2D/CollisionShape2D
				wind_hit_area_collision.disabled = true
		if has_node("Direction/Wind/AnimatedSprite2D"):
			wind_animated_sprite_2d = $Direction/Wind/AnimatedSprite2D
			wind_animated_sprite_2d.visible = false

func enable_hit_area() -> void:
	if wind_hit_area_collision != null:
		wind_hit_area_collision.disabled = false

func disable_hit_area() -> void:
	if wind_hit_area_collision != null:
		wind_hit_area_collision.disabled = true

func enable_wind() -> void:
	if wind_hit_area_collision != null:
		wind_hit_area_collision.disabled = false
	if wind_animated_sprite_2d != null:
		wind_animated_sprite_2d.visible = true

func disable_wind() -> void:
	if wind_hit_area_collision != null:
		wind_hit_area_collision.disabled = true
	if wind_animated_sprite_2d != null:
		wind_animated_sprite_2d.visible = false

func reset_turn_around_delay_timer() -> void:
	turn_around_delay_timer = turn_around_delay

func update_turn_around_delay_timer(delta: float) -> bool:
	turn_around_delay_timer -= delta
	if turn_around_delay_timer <= 0:
		return true
	return false

func ready_to_turn_around() -> bool:
	return turn_around_delay_timer <= 0
