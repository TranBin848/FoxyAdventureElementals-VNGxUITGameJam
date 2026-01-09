extends Area2D
class_name SkillDrop

# ✅ Store Skill resource (level comes from SkillTreeManager)
@export var skill: Skill

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
	float_tween = create_tween().set_loops()
	
	float_tween.tween_property(sprite, "position:y", -5.0, 1.0).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	float_tween.tween_property(sprite, "position:y", 5.0, 1.0).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

	if skill:
		setup_drop(skill, 0)

func _on_detection_player_area_2d_body_entered(body: Node2D):
	if body is Player and skill.type != "ultimate":
		target_player = body as Player
		is_attracted = true
		
		if float_tween and float_tween.is_valid():
			float_tween.kill()
		
		var reset_tween = create_tween()
		reset_tween.tween_property(sprite, "position:y", 0.0, 0.2)
		
func setup_drop(_skill: Skill, stacks: int = 0) -> void:
	skill = _skill
	
	# Set stack amount (use provided value or random)
	if stacks > 0:
		stack_amount = stacks
	else:
		stack_amount = randi_range(min_stack_amount, max_stack_amount)
	
	if sprite and skill.texture_path:
		sprite.texture = load(skill.texture_path)
	
	# Debug label - show current level from SkillTreeManager
	if has_node("Label"):
		var current_level = 1
		if SkillTreeManager:
			current_level = SkillTreeManager.get_level(skill.name)
		$Label.text = "%s\nLv%d x%d" % [skill.name, current_level, stack_amount]

func _physics_process(delta: float) -> void:
	if is_attracted and is_instance_valid(target_player):
		var direction = (target_player.global_position - global_position + Vector2(0, -15)).normalized()
		global_position += direction * attract_speed * delta
		
		if global_position.distance_to(target_player.global_position) < 25:
			_collect_item(target_player)

func _on_body_entered(body: Node2D):
	if body is Player:
		_collect_item(body as Player)

func _collect_item(player: Player) -> void:
	if not skill:
		queue_free()
		return
		
	if (skill.type == "ultimate"):
		match skill.elemental_type:
			ElementsEnum.Elements.FIRE:
				GameProgressManager.trigger_event("FIRE_ULTIMATE")
			ElementsEnum.Elements.WOOD:
				GameProgressManager.trigger_event("WOOD_ULTIMATE")
			ElementsEnum.Elements.METAL:
				GameProgressManager.trigger_event("METAL_ULTIMATE")
			ElementsEnum.Elements.WATER:
				GameProgressManager.trigger_event("WATER_ULTIMATE")
			ElementsEnum.Elements.EARTH:
				GameProgressManager.trigger_event("EARTH_ULTIMATE")
		SkillTreeManager.unlock_skill(skill.name)
	else:
		SkillTreeManager.collect_skill(skill.name, stack_amount)
		player.add_new_skill(skill, stack_amount)
	_play_collect_effect()

func _play_collect_effect() -> void:
	$CollisionShape2D.set_deferred("disabled", true)
	is_attracted = false
	
	var tween = create_tween()
	
	tween.parallel().tween_property(sprite, "scale", Vector2(0.2, 0.2), 0.3).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(sprite, "modulate:a", 0.0, 0.3)
	
	if target_player:
		var heart_pos = target_player.global_position + Vector2(0, -30)
		tween.parallel().tween_property(self, "global_position", heart_pos, 0.4)
	
	tween.tween_callback(queue_free)

func _on_detection_player_area_2d_body_exited(body: Node2D):
	if body is Player and body == target_player:
		target_player = null
		is_attracted = false
