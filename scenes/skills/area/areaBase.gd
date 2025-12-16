extends Area2D
class_name AreaBase

# Class Member Variables
var startupanim: AnimatedSprite2D
var mainanim: AnimatedSprite2D
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
	var hit_area: HitArea2D = null
	targetenemy = enemy
	
	if has_node("HitArea2D"):
		hit_area = $HitArea2D
		hit_area.damage = damage
		hit_area.elemental_type = elemental_type

	mainanim = get_node_or_null("AnimatedSprite2D")
	startupanim = get_node_or_null("StartupAnimatedSprite2D")
	# --- FIX END ---

	# Guard Clause: Use the class variable 'mainanim'
	if not mainanim:
		return

	# Check if we need to run the Startup Sequence
	if startupanim:
		# --- STARTUP SEQUENCE ---
		if not startupanim.animation_finished.is_connected(_on_startup_animation_finished):
			startupanim.animation_finished.connect(
				_on_startup_animation_finished.bind(skill), 
				CONNECT_ONE_SHOT
			)
		
		startupanim.show()
		startupanim.play("startup")
		
		mainanim.stop()
		mainanim.hide()
		
		if hit_area:
			hit_area.set_deferred("monitoring", false)

	else:
		# --- IMMEDIATE CAST (No Startup) ---
		mainanim.show()
		mainanim.play(skill.animation_name)
		
		if hit_area:
			hit_area.set_deferred("monitoring", true)
	
	_setup_duration_timer()

func _on_startup_animation_finished(skill: Skill):
	# 1. Cleanup Startup Animation
	if startupanim:
		startupanim.stop()
		startupanim.visible = false
	
	# 2. Start Main Animation
	if mainanim:
		mainanim.visible = true
		mainanim.play(skill.animation_name)
	
	# 3. Handle Hitbox Activation with Delay
	if has_node("HitArea2D"):
		var hit_area = $HitArea2D
		
		# Assuming your Skill script has a 'hit_delay' float property.
		# If not, you can calculate it manually: (Frame_Number / Animation_FPS)
		var delay_time: float = skill.hit_delay if "hit_delay" in skill else 0.0
		
		if delay_time > 0.0:
			# Wait for the delay
			await get_tree().create_timer(delay_time).timeout
			
			# CRITICAL SAFETY CHECK:
			# Because we waited, this node might have been destroyed (queue_free)
			# by something else (e.g., hitting a wall) during the wait.
			if not is_instance_valid(self) or not is_instance_valid(hit_area):
				return
		
		# Enable the hitbox safely
		hit_area.set_deferred("monitoring", true)

func _setup_duration_timer() -> void:
	# Note: If this node is spawned via code, it might not be inside the tree yet.
	# It is safer to check is_inside_tree() before awaiting ready.
	if not is_inside_tree():
		await ready

	timer = Timer.new()
	timer.wait_time = max(duration, 0.01)
	timer.one_shot = true
	add_child(timer)

	timer.timeout.connect(_on_duration_finished) # Simplified callable syntax
	timer.start()

func _on_duration_finished() -> void:
	# print("Skill expired:", self)
	queue_free()
