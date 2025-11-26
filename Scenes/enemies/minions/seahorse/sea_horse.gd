extends EnemyCharacter

@export var ball_count: int = 3
@export var shoot_force: float = 300
@export var cool_down_time: float = 3
var ball_counter: int = 0
var ball_factory: Node2DFactory
var cool_down_timer: float = 0

func _ready() -> void:
	super._ready()
	fsm = FSM.new(self, $States, $States/Idle)
	_init_ball_factory()

func _init_ball_factory() -> void:
	if has_node("Direction/BallFactory"):
		ball_factory = $Direction/BallFactory
	pass

func shoot() -> void:
	if ball_factory != null:
		var ball = ball_factory.create()
		if ball != null:
			if ball is EnemyCharacter:
				(ball as EnemyCharacter).elemental_type = elemental_type				
				(ball as EnemyCharacter).change_direction(direction)
				(ball as EnemyCharacter).velocity.x = attack_speed * direction
				(ball as EnemyCharacter).spike = attack_damage
				(ball as EnemyCharacter)._ready()
				ball_counter += 1
	pass

func start_cool_down() -> void:
	cool_down_timer = cool_down_time

func update_cool_down_timer(delta: float) -> bool:
	cool_down_timer -= delta
	if cool_down_timer <= 0: return true
	return false
