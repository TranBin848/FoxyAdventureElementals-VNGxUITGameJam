class_name KingCrab
extends EnemyCharacter

# --- REQUIRED SIGNALS ---
signal health_percent_changed(new_value_percent: float)
signal phase_changed(new_phase_index: int)
signal fight_started
signal boss_died

# --- INTERNAL SIGNALS ---
signal state_updated(state_name: String) 

@onready var hit_box: CollisionShape2D = $Direction/HitArea2D/CollisionShape2D
@onready var hurt_box: CollisionShape2D = $Direction/HurtArea2D/CollisionShape2D2
@onready var collision: CollisionShape2D = $CollisionShape2D
@onready var animated_sprite_2d: AnimatedSprite2D = $Direction/AnimatedSprite2D
@onready var claw_factory: Node2DFactory = $Direction/ClawFactory
@onready var label: Label = $Label 

@export_group("Stats")
@export var atk_range: float = 200
@export var skill_cd: float = 10
@export var spin_velocity = 300

@export_group("Phases")
## ORDER: [First Phase, Second Phase, ... Last Phase]
## Index 0 is Full Health. Last Index is Low Health.
@export var phase_order: Array[ElementsEnum.Elements] = [] 

var is_stunned: bool = false
var fired_claw: Node2D = null
var boss_zone: Area2D = null
var is_fighting: bool = false
var changing_phase: bool = false

var current_phase_index: int = 0
var next_phase_index: int = 0

var skills = {
	0: "spin",
	1: "fireclaw"
}
var skill_cd_timer = 0
var cur_skill = 1

func _ready() -> void:
	super._ready()
	fsm = FSM.new(self, $States, $States/Inactive)
	
	# INITIALIZE PHASE LOGIC
	if phase_order.is_empty():
		push_error("KingCrab: Phase Order array is empty in Inspector!")
		phase_order = [ElementsEnum.Elements.EARTH]
	
	# Start at Index 0 (First Item in Array = Full HP Phase)
	current_phase_index = 0
	next_phase_index = 0
	
	elemental_type = phase_order[current_phase_index]
	#call_deferred("apply_element") 

func _physics_process(delta: float) -> void:
	super._physics_process(delta)
	if skill_cd_timer > 0:
		skill_cd_timer -= delta
	
	if fsm.current_state:
		state_updated.emit(fsm.current_state.name)
	
	if label:
		label.text = fsm.current_state.name

func can_use_skill() -> bool:
	if skill_cd_timer > 0: return false
	if is_stunned: return false
	return true
	
func use_skill() -> void:
	var skill = skills[cur_skill]
	fsm.change_state(fsm.states[skill])
	skill_cd_timer = skill_cd
	cur_skill = (cur_skill + 1) % skills.size()

func fire_claw() -> void:
	AudioManager.play_sound("boss_attack")
	var claw = claw_factory.create()
	claw.start_pos = claw_factory.global_position
	claw.global_position = claw_factory.global_position
	claw.atk_range = atk_range
	claw.speed = movement_speed * direction
	claw.direction = direction
	claw.king_crab = self
	fired_claw = claw

func retrieve_claw() -> void:
	fired_claw = null
	fsm.change_state(fsm.states.retrieveclaw)

func take_damage(damage: int) -> void:
	super.take_damage(damage)
	
	AudioManager.play_sound("boss_hurt")
	flash_corountine()
	
	# 1. Calculate Health Percent
	var health_percent = (float(health) / max_health) * 100.0
	
	# 2. Emit Health Signal
	health_percent_changed.emit(health_percent)

	# 3. Calculate Phase Logic (INVERTED)
	if not phase_order.is_empty():
		var total_phases := phase_order.size()
		var bucket_size := 100.0 / total_phases
		
		# Calculate how much health is MISSING
		var health_lost = 100.0 - health_percent
		
		# As health is lost, the index increases (0 -> 1 -> 2)
		next_phase_index = int(health_lost / bucket_size)
		
		# Clamp to ensure we don't go out of bounds (e.g., at 0% HP)
		next_phase_index = clamp(next_phase_index, 0, total_phases - 1)

func update_phase_index() -> void:
	current_phase_index = next_phase_index

func is_phase_changed() -> bool:
	return next_phase_index != current_phase_index

func change_phase() -> void:
	elemental_type = phase_order[current_phase_index]
	apply_element()
	
	# Emit Signal
	phase_changed.emit(current_phase_index)

func apply_element() -> void:
	_init_material()
	_init_particle()
	
	match elemental_type:
		ElementsEnum.Elements.METAL:
			AudioManager.play_sound("metal impact")
			pass
			
		ElementsEnum.Elements.WOOD:
			AudioManager.play_sound("branch cracking")
			pass
			
		ElementsEnum.Elements.WATER:
			pass
			
		ElementsEnum.Elements.FIRE:
			AudioManager.play_sound("fire burst")
			pass
			
		ElementsEnum.Elements.EARTH:
			AudioManager.play_sound("rock impact")
			pass

func flash_corountine() -> void:
	animated_sprite_2d.modulate = Color(20, 20, 20)
	await get_tree().create_timer(0.3).timeout
	animated_sprite_2d.modulate = Color.WHITE

func start_fight() -> void:
	is_fighting = true
	fight_started.emit()

func handle_dead() -> void:
	hurt_box.disabled = true
	collision.disabled = true
	hit_box.disabled = true
	gravity = 0
	velocity.x = 0
	elemental_type = -1
	$Particles.visible = false
	
	boss_died.emit()
	
	if boss_zone:
		boss_zone._on_boss_dead()
	
func is_at_camera_edge(margin: float = 15.0) -> bool:
	var cam := get_viewport().get_camera_2d()
	if cam == null: return false
	var viewport := get_viewport()
	var screen_size := viewport.get_visible_rect().size
	var canvas_xform := viewport.get_canvas_transform().affine_inverse()
	var left_edge  = canvas_xform * Vector2(0, screen_size.y * 0.5)
	var right_edge = canvas_xform * Vector2(screen_size.x, screen_size.y * 0.5)
	var x := global_position.x
	return (x <= left_edge.x + margin and velocity.x < 0) or (x >= right_edge.x - margin and velocity.x > 0)
	
