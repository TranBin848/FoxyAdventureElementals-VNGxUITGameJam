class_name WarLordRocket
extends RigidBody2D


func launch(start_pos: Vector2):
	position = start_pos

func _on_hit_area_2d_hitted(_area: Variant) -> void:
	print("destroy by hit area")
	queue_free()

func _on_body_entered(_body: Node) -> void:
	spawn_explosion(global_position)
	queue_free()
	print("destroy body entered")

func spawn_explosion(pos):
	var e = preload("res://scenes/enemies/war_lord_turtle/warlord_bullets/explosion_particle.tscn").instantiate()
	e.global_position = pos
	e.one_shot = true
	get_tree().current_scene.add_child(e)
