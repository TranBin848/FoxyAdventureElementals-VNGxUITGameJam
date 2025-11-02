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
@export var skill_throw_speed: float = 200
@onready var blade_factory: Node2DFactory = $Direction/BladeFactory
@onready var jump_fx_factory: Node2DFactory = $Direction/JumpFXFactory
@onready var skill_factory: Node2DFactory = $Direction/SkillFactory

@export var push_strength = 100.0

func _ready() -> void:
	super._ready()
	fsm = FSM.new(self, $States, $States/Idle)
	add_to_group("player")
	
	if has_blade:
		collected_blade()
	
	
	#=====SKILL_SYSTEM=======================
	#await get_tree().create_timer(1).timeout
	#single_shot()
	#
	#await get_tree().create_timer(2).timeout
	#multi_shot()
	#
	#await get_tree().create_timer(2).timeout
	#radial(18)
	#=====END_SKILL_SYSTEM==================
	

func _physics_process(delta: float) -> void:
	super._physics_process(delta)
	
	handle_invulnerable(delta)
		
	for i in get_slide_collision_count():
		var c = get_slide_collision(i)
		var body = c.get_collider()
		
		if body is RigidBody2D:
			var normal = -c.get_normal()
			body.apply_central_impulse(normal * push_strength)
			
func handle_invulnerable(delta) -> void:
	if (invulnerable_timer > 0):
		invulnerable_timer -= delta
	else:
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

func single_shot(animation_name = "Fire"):
	var skill = skill_factory.create() as Area2D
	skill.play(animation_name)
	if(direction == 1): 
		skill.direction = Vector2.RIGHT
	else:
		skill.direction = Vector2.LEFT 
	
	
func multi_shot(count: int = 3, delay: float = 0.3, animation_name = "Fire"):
	for i in range(count):
		single_shot(animation_name)
		await get_tree().create_timer(delay).timeout
	
func angled_shot(angle, i):
	var skill = skill_factory.create() as Area2D
	
	if i % 2 == 0:
		skill.play("Fire")
	else:
		skill.play("WaterBlast")
	
	skill.direction = Vector2(cos(angle), sin(angle))

func radial(count):
	for i in range(count):
		angled_shot( (float(i) / count) * 2.0 * PI, i )

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
	jump_fx_factory.create() as Node2D

func _on_hurt_area_2d_hurt(_direction: Variant, _damage: Variant) -> void:
	fsm.current_state.take_damage(_direction, _damage)
