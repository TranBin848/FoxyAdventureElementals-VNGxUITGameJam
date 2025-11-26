extends EnemyCharacter

func _ready() -> void:
	change_animation("default")
	super._ready()

func _on_spike_hit_area_2d_area_entered(area: Area2D) -> void:
	queue_free()

func _on_spike_hit_area_2d_body_entered(body: Node2D) -> void:
	queue_free()
