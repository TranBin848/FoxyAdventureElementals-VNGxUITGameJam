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

func update_facing_visuals() -> void:
	# STANDARD ART RULE: 
	# If your sprite is drawn facing RIGHT -> Flip when direction.x < 0
	# If your sprite is drawn facing LEFT  -> Flip when direction.x > 0
	
	var should_flip = direction.x < 0 # Assuming art faces Right
	
	if has_node("Skill"): get_node("Skill").flip_h = should_flip
	if has_node("FX"): get_node("FX").flip_h = should_flip

func _on_animation_finished(_anim_name: String) -> void:
	queue_free()

func _physics_process(_delta: float) -> void:
	pass
func _update_facing() -> void:
	# Flip sprites based on direction passed from the spawner
	var facing_left = direction.x > 0
	
	if has_node("Skill"): get_node("Skill").flip_h = facing_left
	if has_node("FX"): get_node("FX").flip_h = facing_left
