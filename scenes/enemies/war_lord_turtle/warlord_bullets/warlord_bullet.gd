class_name WarLordBullet
extends RigidBody2D

@export var explode_sfx: AudioStream = null
@export var gravity := 980.0
@export var angle := -45.0

var has_exploded := false
@onready var sprite: Sprite2D = $Sprite2D   # Đổi path nếu tên khác


func fire(start_pos: Vector2, target_pos: Vector2, angle_deg: float, dir: float):
	position = start_pos
	# var v = compute_initial_velocity(start_pos, target_pos, angle_deg, gravity) * dir
	var v = Vector2(200 * dir, -200)
	linear_velocity = v


func compute_initial_velocity(p0: Vector2, p1: Vector2, angle_deg: float, g: float) -> Vector2:
	var length = p0.x - p1.x
	var vel0 = sqrt((abs(g) * length) / sin(2.0 * deg_to_rad(angle)))
	var vel_x = vel0 * cos(deg_to_rad(angle))
	var vel_y = vel0 * sin(deg_to_rad(angle))
	return Vector2(vel_x, vel_y)


func _on_hit_area_2d_hitted(_area: Variant) -> void:
	explode()


func _on_body_entered(_body: Node) -> void:
	if has_exploded:
		return
	has_exploded = true
	wait_and_explode()


func wait_and_explode() -> void:
	
	await get_tree().create_timer(2.5).timeout
	await blink_warning(1.0)
	explode()

func explode() -> void:
	var e = preload("res://scenes/enemies/war_lord_turtle/warlord_bullets/explosion_particle.tscn").instantiate()
	
	e.global_position = global_position
	e.one_shot = true
	get_tree().current_scene.add_child(e)
	
	var area = preload("res://scenes/enemies/war_lord_turtle/warlord_bullets/ExplosionArea.tscn").instantiate()
	area.global_position = global_position
	get_tree().current_scene.add_child(area)
	AudioPlayer.play_sound_once(explode_sfx)
	queue_free()

func blink_warning(duration: float) -> void:
	if not sprite:
		return

	var t := 0.0
	var interval := 0.05  # tốc độ nhấp nháy

	while t < duration:
		# bật đỏ
		sprite.modulate = Color(100, 0, 0)
		await get_tree().create_timer(interval).timeout

		# tắt đỏ → trắng
		sprite.modulate = Color(1, 1, 1)
		await get_tree().create_timer(interval).timeout

		t += interval * 2
