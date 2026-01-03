class_name WarLordRocket
extends RigidBody2D

@export var explode_sfx: AudioStream = null

func launch(start_pos: Vector2, velo: Vector2):
	global_position = start_pos
	apply_impulse(velo)
	
func _integrate_forces(state):
	if linear_velocity.length() > 0.1:
		rotation = linear_velocity.angle()


func _on_hit_area_2d_hitted(_area: Variant) -> void:
	spawn_explosion(global_position)

func _on_body_entered(_body: Node) -> void:
	spawn_explosion(global_position)

func spawn_explosion(pos):
	var e = preload("res://scenes/enemies/war_lord_turtle/warlord_bullets/explosion_particle.tscn").instantiate()
	e.global_position = pos
	e.one_shot = true
	get_tree().current_scene.add_child(e)
	
	var area = preload("res://scenes/enemies/war_lord_turtle/warlord_bullets/ExplosionArea.tscn").instantiate()
	area.global_position = global_position
	get_tree().current_scene.add_child(area)
	AudioManager.play_sound("war_lord_bomb_explode")
	queue_free()
