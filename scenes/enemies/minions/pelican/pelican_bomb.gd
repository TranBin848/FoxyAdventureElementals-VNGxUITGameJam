extends EnemyCharacter

@export var lifetime: float = 10.0  # Auto-cleanup after 10 seconds

func _ready() -> void:
	change_animation("default")
	super._ready()
	
	# Auto-cleanup after lifetime expires
	get_tree().create_timer(lifetime).timeout.connect(_on_lifetime_expired)

func _on_lifetime_expired() -> void:
	if is_instance_valid(self):
		queue_free()

func _on_spike_hit_area_2d_area_entered(area: Area2D) -> void:
	queue_free()

func _on_spike_hit_area_2d_body_entered(body: Node2D) -> void:
	queue_free()
