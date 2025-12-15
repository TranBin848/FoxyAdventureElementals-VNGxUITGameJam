class_name WarLordTurtle
extends EnemyCharacter

@onready var hit_box: CollisionShape2D = $Direction/HitArea2D/CollisionShape2D
@onready var hurt_box: CollisionShape2D = $Direction/HurtArea2D/CollisionShape2D2
@onready var collision: CollisionShape2D = $CollisionShape2D
@onready var anim: AnimatedSprite2D = $"Direction/AnimatedSprite2D" 

@onready var animated_sprite_2d: AnimatedSprite2D = $Direction/AnimatedSprite2D
@onready var bullet_factory: Node2DFactory = $Direction/BulletFactory
@onready var rocket_factory: Node2DFactory = $Direction/RocketFactory

@onready var health_bar: ProgressBar = $UI/Control/ProgressBar
@onready var label: Label = $Label

var boss_zone: Area2D = null

var is_fighting = false
var is_facing_left = true
var is_attacking = false
var has_delay_state = false

var phase_order := [4,3,2] 
var current_phase_index := 2

func _ready() -> void:
	super._ready()
	fsm = FSM.new(self, $States, $States/Inactive)
	direction = -1

@export var atk_angle: float = -45
func fire() -> void:
	var bullet := bullet_factory.create() as WarLordBullet
	var player_pos: Vector2 = Vector2.ZERO
	AudioManager.play_sound("war_lord_shoot")
	if self.found_player != null:
		player_pos = self.found_player.global_position
	#else :
		#player_pos = global_position
		
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
	var health_percent = (float(health) / max_health) * 100
	health_bar.value = health_percent
	

	var total_phases := phase_order.size()
	var bucket_size := 100.0 / total_phases

	var new_phase_index := int((health_percent) / bucket_size)
	# phòng trường hợp health_percent == 100 => int(...) == total_phases
	new_phase_index = clamp(new_phase_index, 0, total_phases - 1)

	if new_phase_index != current_phase_index:
		if is_attacking:
			has_delay_state = true
		else:
			current_phase_index = new_phase_index
			fsm.change_state(fsm.states.inactive)
		
func flash_corountine() -> void:
	animated_sprite_2d.modulate = Color(20, 20, 20)
	await get_tree().create_timer(0.3).timeout
	animated_sprite_2d.modulate = Color.WHITE  # go back to normal	

func alert_coroutine() -> void:
	var targets = $RocketTargets
	var times = 5;
	for i in times:
		await get_tree().create_timer(0.05).timeout
		targets.visible = true;
		await get_tree().create_timer(0.25).timeout
		targets.visible = false;

func start_fight() -> void:
	health_bar.show()
	is_fighting = true

func change_phase() -> void:
	elemental_type = phase_order[current_phase_index]
	apply_element()

func apply_element() -> void:
	_init_material()
	_init_particle()

func handle_dead() -> void:
	hurt_box.disabled = true
	collision.disabled = true
	hit_box.disabled = true
	gravity = 0
	velocity.x = 0
	health_bar.hide()
	$Particles.hide()
	$GPUParticles2D.hide()
	if boss_zone:
		boss_zone._on_boss_dead()

func get_animation_node() -> Node:
	return anim
