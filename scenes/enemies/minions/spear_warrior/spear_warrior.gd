extends EnemyCharacter

var spear_hit_area_2d: HitArea2D
var spear_collision: CollisionShape2D
var spear_collision_shape: RectangleShape2D

func _ready() -> void:
	super._ready()
	fsm = FSM.new(self, $States, $States/Idle)
	_init_spear_collision()

#func _process(delta: float) -> void:
	#if animated_sprite != null:
		#print(animated_sprite.speed_scale)

func _init_spear_collision() -> void:
	if has_node("Direction/SpearHitArea2D"):
		spear_hit_area_2d = $Direction/SpearHitArea2D
		spear_hit_area_2d.damage = attack_damage
	
	if has_node("Direction/SpearHitArea2D/CollisionShape2D"):
		if $Direction/SpearHitArea2D/CollisionShape2D is CollisionShape2D:
			spear_collision = $Direction/SpearHitArea2D/CollisionShape2D
	if spear_collision != null and spear_collision.shape is RectangleShape2D:
		spear_collision_shape = (spear_collision.shape as RectangleShape2D)
