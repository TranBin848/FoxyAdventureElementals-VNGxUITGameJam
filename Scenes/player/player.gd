class_name Player
extends BaseCharacter

@export var invulnerable_duration: float = 2
var is_invulnerable: bool = false
var invulnerable_timer: float = 0
const FLICKER_INTERVAL := 0.1
var flicker_timer := 0.0

@export var has_blade: bool = false
var blade_hit_area: Area2D
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

# ================================================================
# === SKILL SYSTEM ===============================================
# ================================================================

func cast_spell(skill: Skill) -> void:
	if not skill:
		return

	# Gọi animation cast spell
	print("Casting skill: %s (%s)" % [skill.name, skill.element])

	# Xử lý theo loại skill
	match skill.type:
		"single_shot":
			_single_shot(skill)
		"multi_shot":
			await _multi_shot(skill, 3, 0.3)
		"radial":
			_radial(skill, 18)
		_:
			print("Unknown skill type: %s" % skill.type)

# ====== SINGLE SHOT ======
func _single_shot(skill: Skill) -> void:
	var dir := Vector2.RIGHT if direction == 1 else Vector2.LEFT
	# Đổi sang state cast
	cast_skill(skill.animation_name)
	var projectile = _spawn_projectile(skill, dir)
	if projectile:
		# projectile.setup đã gọi animation; thêm gọi play nếu muốn override
		pass

# ====== MULTI SHOT ======
func _multi_shot(skill: Skill, count: int, delay: float) -> void:
	for i in range(count):
		
		_single_shot(skill)
		await get_tree().create_timer(delay).timeout

# ====== ANGLED SHOT cho radial ======
func _angled_shot(angle: float, i: int, skill: Skill) -> void:
	var dir = Vector2(cos(angle), sin(angle)).normalized()
	var projectile = _spawn_projectile(skill, dir)
	if projectile:
		# ví dụ đổi animation theo index nếu muốn
		if i % 2 == 0:
			projectile.play("Fire")
		elif i % 2 == 1:
			projectile.play("WaterBlast")

# ====== RADIAL (xung quanh) ======
func _radial(skill: Skill, count: int) -> void:
	for i in range(count):
		var angle = (float(i) / count) * 2.0 * PI
		_angled_shot(angle, i, skill)

# ====== TẠO PROJECTILE ======
# bây giờ nhận thêm dir vector và gọi setup()
func _spawn_projectile(skill: Skill, dir: Vector2) -> Area2D:
	# Nếu skill.projectile_scene là PackedScene: instantiate trực tiếp
	var proj_node: Node = null
	if skill.projectile_scene:
		proj_node = skill.projectile_scene.instantiate()
	else:
		# fallback dùng factory (nếu bệ hạ vẫn muốn dùng skill_factory)
		proj_node = skill_factory.create() if skill_factory else null

	if not proj_node:
		return null

	var proj = proj_node as Area2D
	if proj == null:
		return null

	# nếu có method setup, gọi nó; nếu không, set thẳng thuộc tính
	if proj.has_method("setup"):
		proj.setup(skill, dir)
	else:
		# fallback: gán thủ công
		if proj.has_variable("speed"):
			proj.speed = skill.speed
		if proj.has_variable("damage"):
			proj.damage = skill.damage
		if proj.has_variable("direction"):
			proj.direction = dir

	proj.global_position = skill_factory.global_position
	
	# add to scene tree
	get_tree().current_scene.add_child(proj)

	return proj

# ================================================================
# === END SKILL SYSTEM ===========================================
# ================================================================

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

func cast_skill(skill_name: String) -> void:
	if fsm.current_state != fsm.states.castspell:
		fsm.change_state(fsm.states.castspell)

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
