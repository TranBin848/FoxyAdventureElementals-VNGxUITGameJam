extends Area2D
class_name AreaBase

var anim_player: AnimationPlayer
var targetenemy: EnemyCharacter
var damage: int
var elemental_type: int
var duration: float
var direction: Vector2
var targets_in_area: Array = [] 
var timer: Timer

func setup(skill: Skill, caster_position: Vector2, enemy: EnemyCharacter, direction: Vector2 = Vector2.RIGHT) -> void:
	self.damage = skill.damage
	self.elemental_type = skill.elemental_type
	self.duration = skill.duration
	self.direction = direction
	self.global_position = caster_position
	
	targetenemy = enemy
	
	# --- FIX START: Safely determine facing direction ---
	var is_facing_right = true
	
	if enemy and is_instance_valid(enemy):
		# If we have a target, look at them
		var direction_to_enemy = (enemy.global_position - caster_position).normalized()
		is_facing_right = direction_to_enemy.x > 0
	else:
		# If enemy is null, use the fallback 'direction' passed from the player
		is_facing_right = direction.x > 0
	# --- FIX END ---
	
	# Flip sprite based on direction
	var sprite = get_node_or_null("Sprite2D")
	if sprite:
		sprite.flip_h = not is_facing_right  # Flip if facing left
	
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
