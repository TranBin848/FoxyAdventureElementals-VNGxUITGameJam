class_name WarLordTurtle
extends EnemyCharacter

@onready var hit_box: CollisionShape2D = $Direction/HitArea2D/CollisionShape2D
@onready var hurt_box: CollisionShape2D = $Direction/HurtArea2D/CollisionShape2D2
@onready var collision: CollisionShape2D = $CollisionShape2D

@onready var animated_sprite_2d: AnimatedSprite2D = $Direction/AnimatedSprite2D
@onready var bullet_factory: Node2DFactory = $Direction/BulletFactory
@onready var rocket_factory: Node2DFactory = $Direction/RocketFactory

@onready var health_bar: ProgressBar = $UI/Control/ProgressBar
@onready var label: Label = $Label


@export var attack_sfx: AudioStream = null
@export var hurt_sfx: AudioStream = null

var is_stunned: bool = false
var fired_claw: Node2D = null
var boss_zone: Area2D = null
var is_fighting: bool = false

var is_facing_left = true


func _ready() -> void:
	super._ready()
	fsm = FSM.new(self, $States, $States/Idle)
	direction = -1

@export var atk_angle: float = -45
func fire() -> void:
	var bullet := bullet_factory.create() as WarLordBullet
	var player_pos: Vector2 = Vector2.ZERO
	
	if self.found_player != null:
		player_pos = self.found_player.global_position
		
	if is_facing_left == true:
		bullet.fire(get_fire_poss(), player_pos, atk_angle, -1)
	else:
		bullet.fire(get_fire_poss(), player_pos,atk_angle, 1)

func launch() -> void:
	pass

func get_fire_poss() -> Vector2:
	if is_facing_left:
		return global_position + Vector2(-45, -25)
	else :
		return global_position + Vector2(45, -25)
