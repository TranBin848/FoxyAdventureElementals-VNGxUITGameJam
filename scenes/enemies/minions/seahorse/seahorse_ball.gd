extends EnemyCharacter

@export var lifetime: float = 3.0  # Auto-cleanup after 10 seconds

func _ready() -> void:
	gravity = 0
	change_animation("default")
	super._ready()

	# Auto-cleanup after lifetime expires
	var timer = get_tree().create_timer(lifetime, true)
	if timer:
		timer.timeout.connect(_on_lifetime_expired)

func _on_lifetime_expired() -> void:
	if is_instance_valid(self):
		queue_free()

func _on_spike_hit_area_2d_area_entered(area: Area2D) -> void:
	queue_free()


func _on_spike_hit_area_2d_body_entered(body: Node2D) -> void:
	queue_free()
