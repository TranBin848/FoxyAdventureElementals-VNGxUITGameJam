class_name KingCrab
extends EnemyCharacter

var is_stunned: bool = false
@onready var claw_factory: Node2DFactory = $Direction/ClawFactory
@export var atk_range: float = 200
@export var skill_cd: float = 10
@onready var health_bar: ProgressBar = $UI/ProgressBar
@onready var animated_sprite_2d: AnimatedSprite2D = $Direction/AnimatedSprite2D
@onready var label: Label = $Label

var skills = {
	0: "spin",
	1: "fireclaw"
}
var skill_cd_timer = 0
var cur_skill = 1

func _ready() -> void:
	super._ready()
	fsm = FSM.new(self, $States, $States/Inactive)
	

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
	fsm.change_state(fsm.states[skills[cur_skill]])
	skill_cd_timer = skill_cd
	cur_skill = (cur_skill + 1) % skills.size()
	pass

func fire_claw() -> void:
	var claw = claw_factory.create()
	claw.start_pos = claw_factory.global_position
	claw.global_position = claw_factory.global_position
	claw.atk_range = atk_range
	claw.speed = movement_speed * direction
	claw.direction = direction

func retrieve_claw() -> void:
	fsm.change_state(fsm.states.retrieveclaw)

func take_damage(damage: int) -> void:
	super.take_damage(damage)
	flash_corountine()
	var health_percent = (float(health) / max_health) * 100
	#print("health: " + str(health) + " max health: " + str(max_health) + " percent: " + str(health_percent))
	health_bar.value = health_percent
	
func flash_corountine() -> void:
	animated_sprite_2d.modulate = Color(20, 20, 20)
	await get_tree().create_timer(0.3).timeout
	animated_sprite_2d.modulate = Color.WHITE  # go back to normal	

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
