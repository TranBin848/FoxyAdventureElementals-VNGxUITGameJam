extends RigidBody2D

@export var blade_scene: PackedScene
@export var flying_sfx: AudioStream = null
@export var rotation_speed: float = 10

@export_group("Gravity Settings")
@export var time_to_max_gravity: float = 1.5 ## How long (t) to reach full gravity
@export var max_gravity_scale: float = 1.0 ## The final gravity strength (1.0 is normal gravity)

var direction: float = 1
var dropped: bool = false

func _ready():
	# 1. Setup Audio
	var player = AudioStreamPlayer2D.new()
	add_child(player)
	player.bus = "SFX"
	player.stream = flying_sfx
	player.play()
	
	# 2. Setup Gravity Transition
	gravity_scale = 0.0 # Start with no gravity (floating straight)
	
	# Create a tween to transition gravity_scale to max_gravity_scale over time_to_max_gravity
	var tween = create_tween()
	tween.tween_property(self, "gravity_scale", max_gravity_scale, time_to_max_gravity).set_trans(Tween.TRANS_LINEAR)

func _physics_process(delta: float) -> void:
	rotation += rotation_speed * delta * direction
	
func _on_body_entered(_body: Node) -> void:
	if dropped:
		return
	drop_blade()

func _on_hit_area_2d_hitted(area: Variant) -> void:
	if dropped:
		return
	drop_blade()
	
func drop_blade() -> void:
	dropped = true
	var blade = blade_scene.instantiate()
	blade.global_position = global_position
	get_tree().current_scene.add_child(blade)
	queue_free()
