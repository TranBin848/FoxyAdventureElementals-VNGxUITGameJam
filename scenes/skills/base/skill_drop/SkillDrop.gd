extends Area2D
class_name SkillDrop

# ✅ Updated: Store full Skill resource (not just Script)
@export var skill_resource: Skill  # Leveled Skill from enemy drop
var skill_name: String = ""
var skill_texture_path: String = ""

@onready var sprite: Sprite2D = $Sprite2D
@onready var detection_area: Area2D = $DetectionPlayerArea2D  # Add this child Area2D!

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

# ✅ Updated setup for leveled Skill resources
func setup_drop(skill: Skill, display_name: String, texture_path: String) -> void:
	skill_resource = skill  # Store full Skill (with level!)
	skill_name = display_name  # "Fireball Lv2"
	skill_texture_path = texture_path
	
	if sprite and skill_texture_path:
		sprite.texture = load(skill_texture_path)
	
	# Debug label (optional)
	if has_node("Label"):
		$Label.text = "%s\nLv%d" % [skill.name, skill.level]

func _physics_process(delta: float) -> void:
	if is_attracted and is_instance_valid(target_player):
		var direction = (target_player.global_position - global_position + Vector2(0,-15)).normalized()
		global_position += direction * attract_speed * delta
		
		if global_position.distance_to(target_player.global_position) < 25:
			_collect_item(target_player)

func _on_body_entered(body: Node2D):
	if body is Player:
		_collect_item(body as Player)

# ✅ Updated: Pass full Skill resource + level
func _collect_item(player: Player) -> void:
	if not skill_resource:
		queue_free()
		return
	
	# Add skill with level to player (update SkillTreeManager.add_stack())
	var success = player.add_new_skill(skill_resource)  # Pass Skill, not Script!
	
	if success:
		print("✅ Collected %s Lv%d!" % [skill_name, skill_resource.level])
		_play_collect_effect()
	else:
		print("❌ Failed to add skill: %s" % skill_name)

func _play_collect_effect() -> void:
	$CollisionShape2D.set_deferred("disabled", true)
	is_attracted = false
	
	var tween = create_tween()
	
	# Scale down + fade + fly to player heart
	tween.parallel().tween_property(sprite, "scale", Vector2(0.2, 0.2), 0.3).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(sprite, "modulate:a", 0.0, 0.3)
	
	if target_player:
		var heart_pos = target_player.global_position + Vector2(0, -30)
		tween.parallel().tween_property(self, "global_position", heart_pos, 0.4)
	
	tween.tween_callback(queue_free)

func _on_detection_player_area_2d_body_entered(body: Node2D):
	if body is Player:
		target_player = body as Player
		is_attracted = true
		if float_tween and float_tween.is_valid():
			float_tween.stop()
		print("🎯 %s attracted to player!" % skill_name)

func _on_detection_player_area_2d_body_exited(body: Node2D):
	if body is Player and body == target_player:
		target_player = null
		is_attracted = false
