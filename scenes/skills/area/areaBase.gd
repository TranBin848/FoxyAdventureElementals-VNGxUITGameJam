extends Area2D
class_name AreaBase

var anim_player: AnimationPlayer
var targetenemy: EnemyCharacter
var damage: float
var elemental_type: ElementsEnum.Elements = ElementsEnum.Elements.NONE
var duration: float
var direction: Vector2
var targets_in_area: Array = [] 
var timer: Timer
var skill: Skill  # ✅ ADD THIS - Store reference to skill for level checks

func setup(_skill: Skill, caster_position: Vector2, enemy: EnemyCharacter, _direction: Vector2 = Vector2.RIGHT) -> void:
	# Store the skill reference FIRST
	skill = _skill
	
	# Use scaled values from skill
	self.damage = skill.get_scaled_damage()
	self.elemental_type = skill.elemental_type
	self.duration = skill.get_scaled_duration()
	self.direction = _direction
	
	targetenemy = enemy
	
	# --- Safely determine facing direction ---
	var is_facing_right = true
	
	if enemy and is_instance_valid(enemy):
		# If we have a target, look at them
		var direction_to_enemy = (enemy.global_position - caster_position).normalized()
		is_facing_right = direction_to_enemy.x > 0
		self.global_position = enemy.global_position
	else:
		self.global_position = caster_position
		# If enemy is null, use the fallback 'direction' passed from the player
		is_facing_right = direction.x > 0
	
	# Flip the entire root or specific containers
	if not is_facing_right:
		scale.x = -1 
	else:
		scale.x = 1
	
	var hit_area: HitArea2D = null
	if has_node("HitArea2D"):
		hit_area = $HitArea2D
		hit_area.damage = damage
		hit_area.elemental_type = elemental_type
		hit_area.set_deferred("monitoring", false)

	anim_player = get_node_or_null("AnimationPlayer")
	if not anim_player:
		return

	anim_player.play(skill.animation_name)
	_setup_duration_timer()

# Called by method track in animation
func _enable_hitbox() -> void:
	if has_node("HitArea2D"):
		$HitArea2D.set_deferred("monitoring", true)
		
func _disable_hitbox() -> void:
	if has_node("HitArea2D"):
		$HitArea2D.set_deferred("monitoring", false)

# Called by method track when startup completes
func _on_startup_complete() -> void:
	pass 

func _setup_duration_timer() -> void:
	if not is_inside_tree():
		await ready

	timer = Timer.new()
	timer.wait_time = max(duration, 0.01)
	timer.one_shot = true
	add_child(timer)
	timer.timeout.connect(_on_duration_finished)
	timer.start()

func _on_duration_finished() -> void:
	queue_free()
