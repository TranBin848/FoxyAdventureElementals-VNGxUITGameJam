extends EnemyCharacter

@export var attack_interval: float = 1
var attack_timer: float = 0
var default_shoot_angle: float = 45
var coconut_factory: Node2DFactory

func _ready() -> void:
	super._ready()
	fsm = FSM.new(self, $States, $States/Moving)
	_init_coconut_factory()

func _init_coconut_factory() -> void:
	if has_node("Direction/CoconutFactory"):
		coconut_factory = $Direction/CoconutFactory
	pass

func throw() -> void:
	if coconut_factory != null:
		var angle = calculate_angle(position, position + Vector2(movement_range, 0), attack_speed, 980)
		#print((angle))
		for i in 2:
			var coconut = coconut_factory.create()
			if coconut != null:
				if coconut is EnemyCharacter:
					(coconut as EnemyCharacter).elemental_type = elemental_type				
					var dir: float
					if i % 2 == 0: dir = -1
					else: dir = 1
					(coconut as EnemyCharacter).velocity.x = attack_speed * cos(angle) * dir
					(coconut as EnemyCharacter).velocity.y = attack_speed * sin(angle)
					(coconut as EnemyCharacter).spike = attack_damage
					(coconut as EnemyCharacter)._ready()
	pass

func calculate_angle(p0: Vector2, p1: Vector2, v: float, g: float) -> float:
	#print(p0)
	#print(p1)
	#print(v)
	#print(g)
	var deltaX = p1.x - p0.x
	var deltaY = p1.y - p0.y
	
	if abs(deltaX) < 1e-6:
		return deg_to_rad(default_shoot_angle)
	
	var A = g * deltaX * deltaX
	var B = 2 * v * v * deltaX
	var C = g * deltaX * deltaX - 2 * v * v * deltaY
	
	var D = B*B - 4*A*C
	if D < 0:
		return deg_to_rad(default_shoot_angle)
	
	var sqrtD = sqrt(D)
	var tan1 = (-B + sqrtD) / (2*A)
	var tan2 = (-B - sqrtD) / (2*A)
	
	var angle1 = atan(tan1)
	var angle2 = atan(tan2)
	
	return angle1 if abs(angle1) > abs(angle2) else angle2

func reset_attack_timer() -> void:
	attack_timer = attack_interval

func update_attack_timer(delta: float) -> bool:
	if is_frozen: return false
	attack_timer -= delta
	if attack_timer <= 0: return true
	return false
