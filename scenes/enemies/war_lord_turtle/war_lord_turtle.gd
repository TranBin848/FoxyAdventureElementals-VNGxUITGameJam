class_name WarLordTurtle
extends EnemyCharacter

signal damaged(amount: int)
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
@onready var anim: AnimatedSprite2D = $"Direction/AnimatedSprite2D" 

@onready var animated_sprite_2d: AnimatedSprite2D = $Direction/AnimatedSprite2D
@onready var bullet_factory: Node2DFactory = $Direction/BulletFactory
@onready var rocket_factory: Node2DFactory = $Direction/RocketFactory

@onready var health_bar: ProgressBar = $UI/Control/ProgressBar
@onready var boss_healthbar: BossHealthBar = $UI/BossHealthbar

@onready var label: Label = $Label

var boss_zone: Area2D = null

var is_fighting = false
var is_facing_left = true
var is_attacking = false
var has_delay_state = false

var being_controled = false

# --- PHASE LOGIC (Imported from KingCrab) ---
@export_group("Phases")
## ORDER: [First Phase, Second Phase, ... Last Phase]
## Index 0 is Full Health. Last Index is Low Health.
@export var phase_order: Array[ElementsEnum.Elements] = [] 

var current_phase_index: int = 0
var next_phase_index: int = 0

func _ready() -> void:
	super._ready()
	fsm = FSM.new(self, $States, $States/Inactive)
	direction = -1
	
	# INITIALIZE PHASE LOGIC
	if phase_order.is_empty():
		push_warning("WarLordTurtle: Phase Order array is empty in Inspector! Defaulting.")
		# Default fallback if empty
		phase_order = [ElementsEnum.Elements.FIRE, ElementsEnum.Elements.METAL, ElementsEnum.Elements.EARTH]
	
	# Start at Index 0 (First Item in Array = Full HP Phase)
	current_phase_index = 0
	next_phase_index = 0
	elemental_type = phase_order[current_phase_index]

@export var atk_angle: float = -45

func _physics_process(delta: float) -> void:
	super._physics_process(delta)
	# Optional: Update label for debugging like KingCrab
	if label and fsm.current_state:
		label.text = fsm.current_state.name

func fire() -> void:
	var bullet := bullet_factory.create() as WarLordBullet
	var player_pos: Vector2 = Vector2.ZERO
	AudioManager.play_sound("war_lord_shoot")
	if self.found_player != null:
		player_pos = self.found_player.global_position
		
	if is_facing_left == true:
		bullet.fire(get_fire_poss(), player_pos, atk_angle, -1)
	else:
		bullet.fire(get_fire_poss(), player_pos,atk_angle, 1)

var targets: Array[Vector2] = [
	Vector2(100, -600),
	Vector2(-100, -600),
	Vector2(150, -600),
	Vector2(-150, -600),
	Vector2(200, -600),
	Vector2(-200, -600)
]
var fire_point: Array[Vector2] = [
	Vector2(30, -35),
	Vector2(-30, -35)
]

func launch(index: int) -> void:
	if targets.is_empty() or fire_point.is_empty():
		return
	alert_coroutine()

	var rocket := rocket_factory.create() as WarLordRocket
	rocket.launch(global_position + fire_point[index % fire_point.size()], targets[index])
	AudioManager.play_sound("war_lord_launch")
	
func get_fire_poss() -> Vector2:
	if is_facing_left:
		return global_position + Vector2(-45, -25)
	else :
		return global_position + Vector2(45, -25)

func take_damage(damage: int) -> void:
	super.take_damage(damage)
	
	AudioManager.play_sound("war_lord_hurt")
	flash_corountine()
	
	if (being_controled): 
		emit_signal("damaged", damage)
		return
	
	# 1. Calculate Health Percent
	var health_percent = (float(health) / max_health) * 100.0
	health_bar.value = health_percent
	
	# 2. Emit Health Signal
	health_percent_changed.emit(health_percent)
	#print(name + " health percent: " + str(health_percent))

	# 3. Calculate Phase Logic (Matches KingCrab: 0 -> Max)
	if not phase_order.is_empty():
		var total_phases := phase_order.size()
		var bucket_size := 100.0 / total_phases
		
		# Calculate how much health is MISSING
		var health_lost = 100.0 - health_percent
		
		# As health is lost, the index increases (0 -> 1 -> 2)
		next_phase_index = int(health_lost / bucket_size)
		
		# Clamp to ensure we don't go out of bounds
		next_phase_index = clamp(next_phase_index, 0, total_phases - 1)

	# 4. Handle State Transition
	if next_phase_index != current_phase_index:
		if is_attacking:
			has_delay_state = true
		else:
			fsm.change_state(fsm.states.inactive)
		
func flash_corountine() -> void:
	animated_sprite_2d.modulate = Color(20, 20, 20)
	await get_tree().create_timer(0.3).timeout
	animated_sprite_2d.modulate = Color.WHITE 

func alert_coroutine() -> void:
	var targets = $RocketTargets
	var times = 5;
	for i in times:
		await get_tree().create_timer(0.05).timeout
		targets.visible = true;
		await get_tree().create_timer(0.25).timeout
		targets.visible = false;

func start_fight() -> void:
	if(!being_controled):
		health_bar.show()
	else:
		boss_healthbar.hide()
	is_fighting = true
	fight_started.emit()

# Called usually from the State Machine (Inactive State) when ready
func update_phase_index() -> void:
	current_phase_index = next_phase_index

func change_phase() -> void:
	# Update element
	elemental_type = phase_order[current_phase_index]
	apply_element()
	
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

func handle_dead() -> void:
	hurt_box.disabled = true
	collision.disabled = true
	hit_box.disabled = true
	gravity = 0
	velocity.x = 0
	health_bar.hide()
	$Particles.hide()
	$GPUParticles2D.hide()
	
	boss_died.emit()
	
	if boss_zone and !being_controled:
		boss_zone._on_boss_dead()

func get_animation_node() -> Node:
	return anim
