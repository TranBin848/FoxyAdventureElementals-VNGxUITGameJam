extends EnemyCharacter

@export var drop_bomb_interval: float = 2
@export var leave_time: float = 10
@export var fly_force: float = 200
@export var drop_bomb_angle: float = 0
@export var drop_bomb_force: float = 350

var ground_ray_cast: RayCast2D
var leave_timer: float
var bomb_factory: Node2DFactory

func _ready() -> void:
	super._ready()
	fsm = FSM.new(self, $States, $States/Moving)
	_init_ground_ray_cast()
	_init_leave_timer()
	_init_bomb_factory()

func _init_ground_ray_cast():
	if has_node("Direction/FrontRayCast2D"):
		ground_ray_cast = $Direction/GroundRayCast2D

func _ground_check() -> bool:
	return ground_ray_cast != null and ground_ray_cast.is_colliding()

func _init_leave_timer() -> void:
	leave_timer = leave_time

func update_leave_timer(_delta: float) -> bool:
	leave_timer -= _delta
	return leave_timer <= 0

func _init_bomb_factory() -> void:
	if has_node("Direction/BombFactory"):
		bomb_factory = $Direction/BombFactory
	pass

func drop_bomb() -> void:
	if bomb_factory != null:
		var bomb = bomb_factory.create()
		if bomb != null:
			if bomb is EnemyCharacter:
				var drop_direction : Vector2 = Vector2.DOWN.rotated(deg_to_rad(drop_bomb_angle * -direction)).normalized()
				(bomb as EnemyCharacter).velocity = drop_direction * drop_bomb_force
				(bomb as EnemyCharacter).elemental_type = elemental_type				
				(bomb as EnemyCharacter).spike = attack_damage
				(bomb as EnemyCharacter)._ready()
	pass
