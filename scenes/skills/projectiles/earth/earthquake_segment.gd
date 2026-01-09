class_name EarthquakeSegment
extends ProjectileBase

func _ready() -> void:
	speed = 0
	
	# Play Animation
	if has_node("AnimationPlayer"):
		var anim = get_node("AnimationPlayer")
		if anim.has_animation("Earthquake"):
			anim.play("Earthquake")
			anim.animation_finished.connect(_on_animation_finished)
		else:
			get_tree().create_timer(1.0).timeout.connect(queue_free)

func setup_hit_area() -> void:
	"""Setup HitArea2D with the scaled damage passed from spawner"""
	if has_node("HitArea2D"):
		var hit_area: HitArea2D = $HitArea2D
		hit_area.damage = damage  # Use the damage set by the spawner
		hit_area.elemental_type = elemental_type

func update_facing_visuals() -> void:
	# Assuming art faces Right -> Flip when direction.x < 0
	var should_flip = direction.x < 0
	
	if has_node("Skill"): 
		get_node("Skill").flip_h = should_flip
	if has_node("FX"): 
		get_node("FX").flip_h = should_flip

func _on_animation_finished(_anim_name: String) -> void:
	queue_free()

func _physics_process(_delta: float) -> void:
	pass  # Segment doesn't move
