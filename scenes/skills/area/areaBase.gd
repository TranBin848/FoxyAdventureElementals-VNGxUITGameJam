extends Area2D
class_name AreaBase

var anim_player: AnimationPlayer
var targetenemy: EnemyCharacter
var damage: int
var elemental_type: int
var duration: float
var targets_in_area: Array = [] 
var timer: Timer

func setup(skill: Skill, caster_position: Vector2, enemy: EnemyCharacter) -> void:
	self.damage = skill.damage
	self.elemental_type = skill.elemental_type
	self.duration = skill.duration
	self.global_position = caster_position
	targetenemy = enemy
	
	var hit_area: HitArea2D = null
	if has_node("HitArea2D"):
		hit_area = $HitArea2D
		hit_area.damage = damage
		hit_area.elemental_type = elemental_type
		hit_area.set_deferred("monitoring", false)

	anim_player = get_node_or_null("AnimationPlayer")
	if not anim_player:
		return

	# Play the appropriate animation based on whether startup exists
	var anim_name = skill.animation_name
	if skill.has_startup and anim_player.has_animation(anim_name + "_startup"):
		anim_player.play(anim_name + "_startup")
	else:
		anim_player.play(anim_name)
		if hit_area:
			hit_area.set_deferred("monitoring", true)
	
	_setup_duration_timer()

# Called by method track in animation
func _enable_hitbox() -> void:
	if has_node("HitArea2D"):
		$HitArea2D.set_deferred("monitoring", true)

# Called by method track when startup completes
func _on_startup_complete() -> void:
	pass  # AnimationPlayer automatically transitions if you use AnimationPlayback tracks

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
