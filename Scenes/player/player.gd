class_name Player
extends BaseCharacter

## Player character class that handles movement, combat, and state management
@export var invulnerable_duration: float = 2
var is_invulnerable: bool = false
var invulnerable_timer: float = 0
const FLICKER_INTERVAL := 0.1
var flicker_timer := 0.0

@export var has_blade: bool = false
var blade_hit_area: Area2D;
@export var blade_throw_speed: float = 300
@onready var blade_factory: Node2DFactory = $Direction/BladeFactory

@onready var jump_fx_factory: Node2DFactory = $Direction/JumpFXFactory

func _ready() -> void:
	super._ready()
	fsm = FSM.new(self, $States, $States/Idle)
	if has_blade:
		collected_blade()

func _physics_process(delta: float) -> void:
	super._physics_process(delta)
	invulnerable_timer -= delta
	
	if (invulnerable_timer <= 0):
		is_invulnerable = false
		
	if is_invulnerable:
		invulnerable_flicker(delta)
	else:
		animated_sprite.modulate.a = 1

func invulnerable_flicker(delta) -> void:
	flicker_timer += delta
	if flicker_timer >= FLICKER_INTERVAL:
		flicker_timer = 0.0
		animated_sprite.modulate.a = 1/(animated_sprite.modulate.a/(0.4*0.7))

func can_attack() -> bool:
	return has_blade

func collected_blade() -> void: 
	has_blade = true
	set_animated_sprite($Direction/BladeAnimatedSprite2D)

func throw_blade() -> void:
	var blade = blade_factory.create() as RigidBody2D
	var throw_velocity := Vector2(blade_throw_speed * direction, 0.0)
	blade.direction = direction
	blade.apply_impulse(throw_velocity)
	throwed_blade()

func throwed_blade() -> void:
	has_blade = false
	set_animated_sprite($Direction/AnimatedSprite2D)

func set_invulnerable() -> void:
	is_invulnerable = true
	invulnerable_timer = invulnerable_duration

func is_char_invulnerable() -> bool:
	return is_invulnerable
	
func jump() -> void:
	super.jump()
	var jump_fx = jump_fx_factory.create() as Node2D

func _on_hurt_area_2d_hurt(_direction: Vector2, _damage: float, _elemental_type: int) -> void:
	# Tính damage dựa trên quan hệ sinh - khắc
	var modified_damage = calculate_elemental_damage(_damage, _elemental_type)
	fsm.current_state.take_damage(_direction, modified_damage)
	handle_elemental_damage(_elemental_type)

func calculate_elemental_damage(base_damage: float, attacker_element: int) -> float:
	# Nếu tấn công không có nguyên tố, dùng damage gốc
	if attacker_element == 0:
		return base_damage
	
	# Định nghĩa quan hệ khắc (lợi thế)
	# Fire (1) > Earth (2), Earth (2) > Water (3), Water (3) > Fire (1)
	var advantage_table = {
		1: [2],  # Fire khắc Earth
		2: [3],  # Earth khắc Water
		3: [1]   # Water khắc Fire
	}
	
	# Định nghĩa quan hệ sinh (bị khắc)
	var weakness_table = {
		1: [3],  # Fire bị Water khắc
		2: [1],  # Earth bị Fire khắc
		3: [2]   # Water bị Earth khắc
	}
	
	# Kiểm tra lợi thế (tấn công khắc phòng thủ)
	if attacker_element in advantage_table and health in advantage_table[attacker_element]:
		return base_damage * 1.25  # +25% damage
	
	# Kiểm tra bất lợi (tấn công bị khắc bởi phòng thủ)
	if attacker_element in weakness_table and elemental_type in weakness_table[attacker_element]:
		return base_damage * 0.75  # -25% damage
	
	return base_damage

func handle_elemental_damage(elemental_type: int) -> void:
	match elemental_type:
		0:  # None
			pass
		1:  # Fire - burn status
			apply_fire_effect()
		2:  # Earth - slow status
			apply_earth_effect()
		3:  # Water - freeze status
			apply_water_effect()

func apply_fire_effect() -> void:
	# Có thể thêm hiệu ứng lửa (burn status, animation, etc)
	pass

func apply_earth_effect() -> void:
	# Có thể thêm hiệu ứng đất (slow, knockback, etc)
	pass

func apply_water_effect() -> void:
	# Có thể thêm hiệu ứng nước (freeze, slow, etc)
	pass
