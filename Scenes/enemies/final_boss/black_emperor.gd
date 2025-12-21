class_name BlackEmperor
extends EnemyCharacter

@onready var hit_box: CollisionShape2D = $Direction/HitArea2D/CollisionShape2D
@onready var hurt_box: CollisionShape2D = $Direction/HurtArea2D/CollisionShape2D2
@onready var collision: CollisionShape2D = $CollisionShape2D

@onready var animated_sprite_2d: AnimatedSprite2D = $Direction/AnimatedSprite2D
@onready var health_bar: ProgressBar = $UI/Control/ProgressBar
@onready var label: Label = $Label

@export var atk_range: float = 200
@export var skill_cd: float = 10
@export var spin_velocity = 300

var is_stunned: bool = false
var boss_zone: Area2D = null
var is_fighting: bool = false

enum Phase {
	FLY,
	GROUND
}

var skills_phase_1 = {
	0: "FlyLightning"
}

var skills_phase_2 = {
	0: "SummonEnemy",
	1: "SpinAttack"
}

var current_phase: Phase = Phase.FLY

var skill_cd_timer = 0
var cur_skill = 0

func _ready() -> void:
	super._ready()
	fsm = FSM.new(self, $States, $States/FlyLightning)
	

func _physics_process(delta: float) -> void:
	super._physics_process(delta)
	if skill_cd_timer > 0:
		skill_cd_timer -= delta
	label.text = str(fsm.current_state)

func can_use_skill() -> bool:
	if skill_cd_timer > 0:
		return false
	if is_stunned:
		return false
	return true
	
func use_skill() -> void:
	if not can_use_skill():
		return

	var skill_dict

	match current_phase:
		Phase.FLY:
			skill_dict = skills_phase_1
		Phase.GROUND:
			skill_dict = skills_phase_2

	var skill = skill_dict[cur_skill]
	fsm.change_state(fsm.states[skill])

	skill_cd_timer = skill_cd
	cur_skill = (cur_skill + 1) % skill_dict.size()


func take_damage(damage: int) -> void:
	super.take_damage(damage)
	
	AudioManager.play_sound("boss_hurt")
	
	flash_corountine()
	var health_percent = (float(health) / max_health) * 100
	health_bar.value = health_percent
	
	if health_percent <= 50 and current_phase == Phase.FLY:
		enter_phase_ground()

func enter_phase_ground() -> void:
	current_phase = Phase.GROUND
	
	cur_skill = 0
	
	# Ép boss thoát skill hiện tại
	fsm.change_state(fsm.states["Idle"])

	# Tắt va chạm bay / bật va chạm đất nếu có
	collision.disabled = false

	# Animation hạ cánh
	animated_sprite_2d.play("land")

	# Có thể stun ngắn để player thấy phase đổi
	is_stunned = true
	await get_tree().create_timer(1.0).timeout
	is_stunned = false
	
func flash_corountine() -> void:
	animated_sprite_2d.modulate = Color(20, 20, 20)
	await get_tree().create_timer(0.3).timeout
	animated_sprite_2d.modulate = Color.WHITE  # go back to normal	

func start_fight() -> void:
	health_bar.show()
	is_fighting = true

func handle_dead() -> void:
	pass
	
func is_at_camera_edge(margin: float = 15.0) -> bool:
	var cam := get_viewport().get_camera_2d()
	if cam == null:
		return false

	var viewport := get_viewport()
	var screen_size := viewport.get_visible_rect().size

	# Convert screen coords → world coords
	var canvas_xform := viewport.get_canvas_transform().affine_inverse()

	var left_edge  = canvas_xform * Vector2(0, screen_size.y * 0.5)
	var right_edge = canvas_xform * Vector2(screen_size.x, screen_size.y * 0.5)

	var x := global_position.x
	#print("camera edges:", left_edge, right_edge, " obj:", x)
	return (x <= left_edge.x + margin and velocity.x < 0) or (x >= right_edge.x - margin and velocity.x > 0) 
