class_name FinalBossPhaseOne
extends EnemyCharacter

@onready var hit_box: CollisionShape2D = $Direction/HitArea2D/CollisionShape2D
@onready var hurt_box: CollisionShape2D = $Direction/HurtArea2D/CollisionShape2D2
@onready var collision: CollisionShape2D = $CollisionShape2D
@onready var anim: AnimatedSprite2D = $"Direction/AnimatedSprite2D" 

@onready var animated_sprite_2d: AnimatedSprite2D = $Direction/AnimatedSprite2D

#node for spawhning 2 mini boss
@onready var energy_center:Node2D = $EnergyCenter

#references
@export var KING_CRAB_SCENE: PackedScene
@export var WAR_LORD_SCENE: PackedScene
@export var ENERGY_LINE_SCENE: PackedScene

var king_crab_instance: KingCrab = null
var war_lord_instance: WarLordTurtle = null

var energy_line_1: EnergyLine = null
var energy_line_2: EnergyLine = null

@onready var health_bar: ProgressBar = $UI/Control/ProgressBar
@onready var label: Label = $Label

var boss_zone: Area2D = null

var is_fighting = false
var movespeed = 1;

func _ready() -> void:
	super._ready()
	fsm = FSM.new(self, $States, $States/Inactive)
	direction = -1
	

func take_damage(damage: int) -> void:
	super.take_damage(damage)
	
	health_bar.show()
	#AudioManager.play_sound("war_lord_hurt")
	
	flash_corountine()
	var health_percent = (float(health) / max_health) * 100
	health_bar.value = health_percent
	

func flash_corountine() -> void:
	animated_sprite_2d.modulate = Color(20, 20, 20)
	await get_tree().create_timer(0.3).timeout
	animated_sprite_2d.modulate = Color.WHITE  # go back to normal	


func start_fight() -> void:
	health_bar.show()
	is_fighting = true;

func spawn_mini_bosses() -> void:

	if !is_instance_valid(king_crab_instance):
		king_crab_instance = KING_CRAB_SCENE.instantiate() as KingCrab
		king_crab_instance.modulate = Color8(144, 0, 255, 255)
		energy_center.add_child(king_crab_instance)
		king_crab_instance.position = Vector2(300, 0)
		
		king_crab_instance.being_controled = true
		king_crab_instance.boss_zone = self.boss_zone
		king_crab_instance.start_fight()


	if !is_instance_valid(war_lord_instance):
		war_lord_instance = WAR_LORD_SCENE.instantiate() as WarLordTurtle
		war_lord_instance.modulate = Color8(144, 0, 255, 255)
		energy_center.add_child(war_lord_instance)
		war_lord_instance.position = Vector2(-300, 0)

		war_lord_instance.being_controled = true
		king_crab_instance.boss_zone = self.boss_zone
		war_lord_instance.start_fight()

	link_to_final_boss()
	set_up_health() 


func link_to_final_boss() -> void: 
	if mini_boss_is_not_ready():
		return
	
	if(energy_line_1 == null):
		energy_line_1 = ENERGY_LINE_SCENE.instantiate() as EnergyLine
		energy_line_1.a = energy_center
		energy_line_1.b = king_crab_instance
		energy_center.add_child(energy_line_1)
	if(energy_line_2 == null):
		energy_line_2 = ENERGY_LINE_SCENE.instantiate() as EnergyLine
		energy_line_2.a = energy_center
		energy_line_2.b = war_lord_instance
		energy_center.add_child(energy_line_2)
	
func set_up_health() -> void:
	
	if mini_boss_is_not_ready():
		return
	
	max_health = king_crab_instance.max_health + war_lord_instance.max_health
	health = max_health
	
	#Set up link
	war_lord_instance.damaged.connect(take_damage)
	king_crab_instance.damaged.connect(take_damage)

func mini_boss_is_not_ready() -> bool:
	return king_crab_instance == null or !is_instance_valid(king_crab_instance) or war_lord_instance == null or !is_instance_valid(war_lord_instance)

func handle_dead() -> void:
	hurt_box.disabled = true
	collision.disabled = true
	hit_box.disabled = true
	gravity = 0
	velocity.x = 0
	health_bar.hide()
	if boss_zone:
		boss_zone._on_boss_dead()

func hide_coroutine_king_crab() -> void:
	fade_out(king_crab_instance, 0.6)
	fade_out(energy_line_1, 0.4)

func hide_coroutine_war_lord() -> void:
	fade_out(war_lord_instance, 0.6)
	fade_out(energy_line_2, 0.4)

func fade_out(node: CanvasItem, duration: float = 0.5) -> void:
	if node == null:
		return

	var tween := create_tween()
	tween.tween_property(node, "modulate:a", 0.0, duration)
	tween.tween_callback(func():
		node.hide()
	)


func get_animation_node() -> Node:
	return anim
