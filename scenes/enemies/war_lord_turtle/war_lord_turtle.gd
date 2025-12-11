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
var is_fighting: bool = false

var is_facing_left = true


func _ready() -> void:
	super._ready()
	fsm = FSM.new(self, $States, $States/Inactive)
	direction = -1

@export var atk_angle: float = -45
func fire() -> void:
	var bullet := bullet_factory.create() as WarLordBullet
	var player_pos: Vector2 = Vector2.ZERO
	
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
	
	Vector2(200, -600),
	Vector2(-200, -600),
	
	Vector2(300, -600),
	Vector2(-300, -600)
]
var firePoint: Array[Vector2] = [
	Vector2(30, -35),
	Vector2(-30, -35)
]

func launch() -> void:
	if targets.is_empty() or firePoint.is_empty():
		return
	alert_coroutine()

	var anim: AnimatedSprite2D = $"Direction/AnimatedSprite2D" 
	if anim == null:
		push_error("AnimatedSprite2D WRONG PATH !")
		return

	for i in range(targets.size()):
		if i % 2 == 0:
			change_animation("launchRocket")
			anim.frame = 0
			anim.play()
			await get_tree().process_frame
			await get_tree().create_timer(0.1).timeout #hold for match anim

		var rocket := rocket_factory.create() as WarLordRocket
		rocket.launch(global_position + firePoint[i % firePoint.size()], targets[i])

		if i  % 2 == 1:
			await anim.animation_finished

	change_animation("rotate2Front")
	anim.frame = 0
	anim.play()
	await get_tree().process_frame
	await anim.animation_finished
	fsm.change_state(fsm.states.stun)

func get_fire_poss() -> Vector2:
	if is_facing_left:
		return global_position + Vector2(-45, -25)
	else :
		return global_position + Vector2(45, -25)

func take_damage(damage: int) -> void:
	super.take_damage(damage)
	
	AudioPlayer.play_sound_once(hurt_sfx)
	
	flash_corountine()
	var health_percent = (float(health) / max_health) * 100
	health_bar.value = health_percent
	#print("health: " + str(health) + " max health: " + str(max_health) + " percent: " + str(health_percent))
	
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

func handle_dead() -> void:
	hurt_box.disabled = true
	collision.disabled = true
	hit_box.disabled = true
	gravity = 0
	velocity.x = 0
	health_bar.hide()
