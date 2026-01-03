extends Area2D
class_name SkillDrop

# ✅ Store full Skill resource (with level data)
@export var skill_resource: Skill
var skill_name: String = ""
var skill_texture_path: String = ""

# ✅ Stack amount configuration
@export_range(1, 10) var min_stack_amount: int = 2
@export_range(1, 10) var max_stack_amount: int = 5
var stack_amount: int = 0  # Set in setup_drop or randomly generated

@onready var sprite: Sprite2D = $Sprite2D
@onready var detection_area: Area2D = $DetectionPlayerArea2D

@export var float_speed: float = 30.0
@export var attract_speed: float = 300.0

var is_attracted: bool = false
var target_player: Player = null
var float_tween: Tween = null

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	detection_area.body_entered.connect(_on_detection_player_area_2d_body_entered)
	detection_area.body_exited.connect(_on_detection_player_area_2d_body_exited)
	
	# Float animation
	float_tween = create_tween().set_loops()
	float_tween.tween_property(self, "position:y", position.y - 5, 1.0).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	float_tween.tween_property(self, "position:y", position.y + 5, 1.0).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

func setup_drop(skill: Skill, display_name: String, texture_path: String, stacks: int = 0) -> void:
	skill_resource = skill  # Store full Skill (with level!)
	skill_name = display_name
	skill_texture_path = texture_path
	
	# Set stack amount (use provided value or random)
	if stacks > 0:
		stack_amount = stacks
	else:
		stack_amount = randi_range(min_stack_amount, max_stack_amount)
	
	if sprite and skill_texture_path:
		sprite.texture = load(skill_texture_path)
	
	# Debug label (optional)
	if has_node("Label"):
		$Label.text = "%s\nLv%d x%d" % [skill.name, skill.level, stack_amount]

func _physics_process(delta: float) -> void:
	if is_attracted and is_instance_valid(target_player):
		var direction = (target_player.global_position - global_position + Vector2(0, -15)).normalized()
		global_position += direction * attract_speed * delta
		
		if global_position.distance_to(target_player.global_position) < 25:
			_collect_item(target_player)

func _on_body_entered(body: Node2D):
	if body is Player:
		_collect_item(body as Player)

# ✅ Pass full Skill resource AND stack amount
func _collect_item(player: Player) -> void:
	if not skill_resource:
		queue_free()
		return
		
	# Add skill through Player with stack amount
	player.add_new_skill(skill_resource, stack_amount)
	
	_play_collect_effect()

func _play_collect_effect() -> void:
	$CollisionShape2D.set_deferred("disabled", true)
	is_attracted = false
	
	var tween = create_tween()
	
	# Scale down + fade + fly to player
	tween.parallel().tween_property(sprite, "scale", Vector2(0.2, 0.2), 0.3).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(sprite, "modulate:a", 0.0, 0.3)
	
	if target_player:
		var heart_pos = target_player.global_position + Vector2(0, -30)
		tween.parallel().tween_property(self, "global_position", heart_pos, 0.4)
	
	tween.tween_callback(queue_free)

func _on_detection_player_area_2d_body_entered(body: Node2D):
	if body is Player and skill_resource.type != "ultimate":
		target_player = body as Player
		is_attracted = true
		if float_tween and float_tween.is_valid():
			float_tween.stop()
		print("🎯 %s attracted to player!" % skill_name)

func _on_detection_player_area_2d_body_exited(body: Node2D):
	if body is Player and body == target_player:
		target_player = null
		is_attracted = false
