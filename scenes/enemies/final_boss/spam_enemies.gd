extends BlackEmperorState
# State triệu hồi spawner - chỉ thực hiện 1 lần khi chuyển phase

func _enter() -> void:
	# Boss bị stun trong suốt quá trình
	obj.is_stunned = true
	obj.is_movable = false
	obj.velocity = Vector2.ZERO
	
	# === BAY VỀ TRUNG TÂM BOSS ZONE ===
	await _fly_to_center()
	
	# === SLOW MOTION + CAMERA ZOOM ===
	Engine.time_scale = 0.3
	
	if obj.boss_zone and obj.boss_zone.camera_2d:
		var boss_camera = obj.boss_zone.camera_2d
		var original_zoom = boss_camera.zoom
		var target_zoom = original_zoom * 1.5  # Zoom in 1.5x
		
		var tween = create_tween()
		tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
		tween.tween_property(boss_camera, "zoom", target_zoom, 0.5)
		await tween.finished
	
	# === ANIMATION TRIỆU HỒI ===
	if obj.animated_sprite_2d:
		if obj.animated_sprite_2d.sprite_frames.has_animation("summon"):
			obj.animated_sprite_2d.play("summon")
		elif obj.animated_sprite_2d.sprite_frames.has_animation("cast"):
			obj.animated_sprite_2d.play("cast")
		elif obj.animated_sprite_2d.sprite_frames.has_animation("hurt"):
			obj.animated_sprite_2d.play("hurt")
		elif obj.animated_sprite_2d.sprite_frames.has_animation("land"):
			obj.animated_sprite_2d.play("land")
	
	# Đợi một chút để player thấy animation triệu hồi
	await get_tree().create_timer(0.5 * Engine.time_scale).timeout
	
	# === SPAWN 5 SPAWNER VỚI HIỆU ỨNG FADE IN ===
	_spawn_star_spawners_with_fade()
	
	# Đợi thêm một chút
	await get_tree().create_timer(0.5 * Engine.time_scale).timeout
	
	# === ZOOM CAMERA VỀ 1.5 ===
	if obj.boss_zone and obj.boss_zone.camera_2d:
		var boss_camera = obj.boss_zone.camera_2d
		var target_zoom = Vector2(1.5, 1.5)
		
		var tween = create_tween()
		tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
		tween.tween_property(boss_camera, "zoom", target_zoom, 0.3)
		await tween.finished
	
	# === TRẢ VỀ TỐC ĐỘ BÌNH THƯỜNG ===
	Engine.time_scale = 1.0
	
	# === HẠ BOSS XUỐNG MẶT ĐẤT CHẬM CHẬM ===
	if obj.animated_sprite_2d:
		obj.animated_sprite_2d.play("land")
	
	await _land_on_ground()
	
	# === SAU KHI HẠ CÁNH XONG, KÍCH HOẠT SPAWNER ===
	_activate_spawners()
	
	obj.is_stunned = false
	obj.is_movable = true
	
	# Chuyển sang state charge
	if fsm.states.has("charge"):
		fsm.change_state(fsm.states.charge)
	else:
		obj.use_skill()

func _fly_to_center() -> void:
	# Tính vị trí trung tâm
	var center_x = obj.global_position.x
	if obj.boss_zone:
		center_x = obj.boss_zone.global_position.x
	
	var center_pos = Vector2(center_x, obj.global_position.y)  # Giữ nguyên độ cao
	
	# Bay về trung tâm nếu chưa ở đó
	if obj.global_position.distance_to(center_pos) > 10:
		var fly_tween = create_tween()
		fly_tween.tween_property(obj, "global_position", center_pos, 0.8).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN_OUT)
		await fly_tween.finished

func _spawn_star_spawners_with_fade() -> void:
	if obj.spawner_scene == null:
		print("Error: spawner_scene not assigned in BlackEmperor!")
		return
	
	# Xóa spawner cũ nếu có
	for s in obj.spawned_spawners:
		if is_instance_valid(s):
			s.queue_free()
	obj.spawned_spawners.clear()
	
	# 5 hệ nguyên tố
	var element_types = [
		ElementsEnum.Elements.METAL,
		ElementsEnum.Elements.WOOD, 
		ElementsEnum.Elements.WATER,
		ElementsEnum.Elements.FIRE,
		ElementsEnum.Elements.EARTH
	]
	
	# Tâm của boss zone theo trục x, y cố định ở trên cao
	var center_x = obj.global_position.x
	var center_y = obj.ground_y - 200  # Y cố định, cao hơn mặt đất
	
	# Nếu có boss_zone, lấy tâm x của boss_zone
	if obj.boss_zone:
		var zone_center = obj.boss_zone.global_position
		center_x = zone_center.x
	
	var center = Vector2(center_x, center_y)
	
	# Góc bắt đầu từ đỉnh trên (-90 độ)
	var start_angle = -PI / 2
	
	for i in range(5):
		var spawner = obj.spawner_scene.instantiate()
		
		# Tính góc cho đỉnh thứ i của ngôi sao (ngũ giác)
		var angle = start_angle + (i * 2 * PI / 5)
		
		# Tính vị trí theo tọa độ cực
		var offset_x = cos(angle) * obj.spawner_radius
		var offset_y = sin(angle) * obj.spawner_radius
		
		spawner.global_position = Vector2(center.x + offset_x, center.y + offset_y)
		
		# Set elemental type
		if "elemental_type" in spawner:
			spawner.elemental_type = element_types[i]
		
		# Set enemies để spawn
		if obj.enemies_to_spawn.size() > 0 and "enemy_to_spawn" in spawner:
			spawner.enemy_to_spawn = obj.enemies_to_spawn
		
		# Set máu spawner
		if "max_health" in spawner:
			spawner.max_health = obj.spawner_health
			spawner.health = obj.spawner_health
		
		# Set spawn_interval chậm hơn
		if "spawn_interval" in spawner:
			spawner.spawn_interval = 8.0
		
		# Pause spawner - chưa cho hoạt động
		if "is_paused" in spawner:
			spawner.is_paused = true
		else:
			spawner.set_process(false)
			spawner.set_physics_process(false)
		
		# === HIỆU ỨNG FADE IN ===
		spawner.modulate = Color(1, 1, 1, 0)  # Trong suốt ban đầu
		
		# Thêm vào scene
		var enemies_container = GameManager.current_stage.find_child("Enemies")
		if enemies_container:
			enemies_container.add_child(spawner)
		else:
			obj.get_parent().add_child(spawner)
		
		obj.spawned_spawners.append(spawner)
		
		# Tween fade in với delay giữa các spawner
		var fade_tween = create_tween()
		fade_tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
		fade_tween.tween_property(spawner, "modulate", Color(1, 1, 1, 1), 0.5).set_delay(i * 0.1)
	
	print("Spawned 5 spawners with fade effect in star shape")

func _activate_spawners() -> void:
	# Kích hoạt tất cả spawner sau khi boss hạ cánh
	for spawner in obj.spawned_spawners:
		if is_instance_valid(spawner):
			if "is_paused" in spawner:
				spawner.is_paused = false
			spawner.set_process(true)
			spawner.set_physics_process(true)
	print("Spawners activated!")

func _land_on_ground() -> void:
	# Di chuyển boss từ vị trí bay xuống mặt đất CHẬM
	var land_speed = 80.0
	
	while obj.global_position.y < obj.ground_y:
		var delta = obj.get_physics_process_delta_time()
		obj.global_position.y += land_speed * delta
		
		if obj.global_position.y >= obj.ground_y:
			obj.global_position.y = obj.ground_y
			break
		
		await get_tree().process_frame
	
	# Đảm bảo boss ở đúng vị trí mặt đất
	obj.global_position.y = obj.ground_y
	
	# Đợi thêm một chút sau khi hạ cánh - boss đứng im
	await get_tree().create_timer(1.0).timeout

func _exit() -> void:
	obj.is_movable = true
	obj.is_stunned = false
