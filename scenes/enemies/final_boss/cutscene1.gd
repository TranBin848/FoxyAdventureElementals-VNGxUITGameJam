extends BlackEmperorState

## Cutscene 1: Di chuyển player và boss về vị trí cutscene với camera zoom
## Flow:
## 1. Player và boss đứng im
## 2. Chuyển camera sang boss camera
## 3. Zoom camera boss vào
## 4. Boss bay lên vị trí BossPosCutscene1 (camera follow)
## 5. Chuyển camera về boss_zone camera
## 6. Hiển thị icon nguyên tố Thổ phóng to + fade
## 7. Zoom camera ra toàn cảnh
## 8. Player bay tới PlayerPosCutscene1
## 9. Trigger AnimatedBg chạy animation cutscene1

# Scene
const ELEMENT_SPRITE_SCENE = preload("res://scenes/enemies/final_boss/element_sprite.tscn")
const FADE_BOSS_SCENE = preload("res://scenes/enemies/final_boss/fade_boss_scene.tscn")

var animated_bg: AnimatedSprite2D = null
var player: Player = null
var player_pos: Node2D = null
var boss_pos: Node2D = null
var boss_camera: Camera2D = null
var boss_zone_camera: Camera2D = null
var boss_locked_position: Vector2 = Vector2.ZERO  # Vị trí lock boss
var is_boss_locked: bool = false  # Flag để lock boss
var canvas_layer: CanvasLayer = null  # CanvasLayer UI cần ẩn đi

func _enter() -> void:
	print("State: Cutscene1 Enter")
	
	obj.change_animation("idle")
	
	await get_tree().create_timer(0.5).timeout
	
	# KILL TẤT CẢ TWEENS từ state cũ ngay lập tức
	var all_tweens = obj.get_tree().get_processed_tweens()
	print("Cutscene1: Killing ", all_tweens.size(), " active tweens")
	for t in all_tweens:
		if t.is_valid():
			t.kill()
	
	# Force đặt lại position ngay lập tức
	obj.velocity = Vector2.ZERO
	obj.is_stunned = true
	obj.is_movable = false
	obj.set_physics_process(false)  # Tắt physics để không bị override position
	is_boss_locked = false
	
	# Tìm AnimatedBg
	if animated_bg == null:
		animated_bg = obj.get_tree().get_first_node_in_group("animated_bg")
	
	# Tìm và ẩn CanvasLayer UI
	if canvas_layer == null:
		canvas_layer = obj.get_tree().root.find_child("GUI", true, false) as CanvasLayer
		if canvas_layer:
			print("Cutscene1: Found CanvasLayer, hiding it")
			canvas_layer.visible = false
		else:
			print("Warning: CanvasLayer not found")
	
	# Tìm position nodes từ PosBossPlayer trong scene hiện tại
	var pos_container = obj.get_tree().root.find_child("PosBossPlayer", true, false)
	if pos_container:
		boss_pos = pos_container.get_node_or_null("BossPosCutscene1")
		player_pos = pos_container.get_node_or_null("PLayerPosCutscene1")		
		if player_pos:
			print("Cutscene1: Found PlayerPosCutscene1 at ", player_pos.global_position)
		if boss_pos:
			print("Cutscene1: Found BossPosCutscene1 at ", boss_pos.global_position)		
		if not player_pos or not boss_pos:
			print("Warning: Position nodes not found in PosBossPlayer")
	else:
		print("Warning: PosBossPlayer container not found")
	
	# Tìm player
	if player == null:
		player = obj.get_tree().root.find_child("Player", true, false) as Player
	
	# Tìm camera boss
	if boss_camera == null:
		boss_camera = obj.get_node_or_null("Camera2D")
	
	# Tìm camera boss_zone
	if boss_zone_camera == null and obj.boss_zone:
		boss_zone_camera = obj.boss_zone.camera_2d
	
	# Bắt đầu sequence
	_start_cutscene_sequence()

func _start_cutscene_sequence() -> void:
	# === STEP 1: DISABLE PLAYER INPUT ===
	if player and player.fsm:
		if player.fsm.states.has("idle"):
			player.fsm.change_state(player.fsm.states.idle)
		player.set_physics_process(false)
	
	# === STEP 2: ĐỨNG IM MỘT CHÚT ===
	await get_tree().create_timer(0.5).timeout
	
	# === STEP 3: CHUYỂN SANG CAMERA BOSS ===
	if boss_camera:
		# Enable camera boss trước
		boss_camera.enabled = true 
		# Chuyển camera
		CameraTransition.transition_camera2D(boss_camera, 1.0)
		await get_tree().create_timer(1.0).timeout
	
	# === STEP 4: ZOOM CAMERA BOSS VÀO ===
	await _zoom_boss_camera_in()
	
	# === STEP 5: BOSS BAY LÊN VỊ TRÍ CUTSCENE (camera boss tự follow) ===
	await _move_boss_to_position()
	
	# === STEP 6: CHUYỂN LẠI CAMERA BOSS_ZONE ===
	if boss_zone_camera:
		print("Cutscene1: Switching back to boss_zone camera")
		print("  Boss position: ", obj.global_position)
		print("  Boss_zone camera position: ", boss_zone_camera.global_position)
		CameraTransition.transition_camera2D(boss_zone_camera, 1.0)
		await get_tree().create_timer(1.0).timeout
	
	# === STEP 7: HIỂN THỊ ICON NGUYÊN TỐ PHÓNG TO + FADE ===
	await _show_element_icons()
	
	# === STEP 8: ZOOM CAMERA RA TOÀN CẢNH ===
	await _zoom_camera_out()
	
	# === STEP 9: PLAYER BAY TỚI VỊ TRÍ CUTSCENE ===
	await _move_player_to_position()
	
	# === STEP 10: BẮT ĐẦU CHẠY ANIMATION CUTSCENE1 ===
	if animated_bg:
		print("Cutscene1: Triggering AnimatedBg to play cutscene1")
		
		# Ẩn player khi bắt đầu animation
		if player:
			player.visible = false
			print("Cutscene1: Player hidden")
		
		animated_bg.play("cutscene1")
		
		# Đợi animation hoàn thành
		await animated_bg.animation_finished
		print("Cutscene1: AnimatedBg cutscene1 finished")
	
	# === STEP 11: FLASH EFFECT (ÁNH SÁNG LÓE) ===
	await _play_flash_effect()
	
	# === STEP 12: THẢ PLAYER XUỐNG ĐẤT ===
	await _land_player_on_ground()
	
	# Đợi 3 giây trước khi chuyển sang cutscene2
	await get_tree().create_timer(1.0).timeout
	
	# Unlock boss trước khi chuyển state
	is_boss_locked = false
	obj.set_physics_process(true)
	
	# Tự chuyển sang Cutscene2 (không dùng signal từ AnimatedBg nữa)
	print("Cutscene1: About to transition to Cutscene2")
	print("  FSM valid: ", is_instance_valid(fsm))
	print("  FSM: ", fsm)
	print("  Has cutscene2: ", fsm.states.has("cutscene2") if fsm else false)
	
	if is_instance_valid(fsm) and fsm.states.has("cutscene2"):
		print("Cutscene1: Finished, transitioning to Cutscene2")
		fsm.change_state(fsm.states.cutscene2)
		print("Cutscene1: After change_state call")
	else:
		print("ERROR: Cannot transition to cutscene2!")

func _zoom_boss_camera_in() -> void:
	# Slow motion
	Engine.time_scale = 0.4


func _move_boss_to_position() -> void:
	if not boss_pos:
		print("Warning: BossPosCutscene1 not found!")
		await get_tree().create_timer(0.5).timeout
		return
	
	var target_pos = boss_pos.global_position
	print("Cutscene1: Moving boss from ", obj.global_position, " to ", target_pos)
	
	# Debug: In ra tất cả tweens đang chạy
	var all_tweens = obj.get_tree().get_processed_tweens()
	print("Cutscene1: Active tweens count BEFORE: ", all_tweens.size())
	
	# Kill tất cả tweens cũ trước khi tạo mới
	for t in all_tweens:
		if t.is_valid():
			t.kill()
	
	# Đợi 1 frame để tweens thực sự bị kill
	await get_tree().process_frame
	
	# Kiểm tra lại
	all_tweens = obj.get_tree().get_processed_tweens()
	print("Cutscene1: Active tweens count AFTER KILL: ", all_tweens.size())
	
	# Disable velocity/physics để không bị override position
	obj.velocity = Vector2.ZERO
	
	obj.change_animation("moving")
	
	# Tạo tween trên obj (boss) thay vì trên state
	var fly_tween = obj.get_tree().create_tween()
	fly_tween.bind_node(obj)  # Bind tween vào boss để tự kill khi boss bị remove
	fly_tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	fly_tween.tween_property(obj, "global_position", target_pos, 1.2).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN_OUT)
	
	# Debug: theo dõi position trong khi tween
	fly_tween.tween_callback(func(): print("Cutscene1: Tween finished callback, boss at: ", obj.global_position))
	
	await fly_tween.finished
	
	# Force lock position sau khi tween xong
	obj.global_position = target_pos
	boss_locked_position = target_pos
	is_boss_locked = true  # Bật lock để _update giữ position
	
	print("Cutscene1: Boss arrived at ", obj.global_position, " (expected: ", target_pos, ")")
	is_boss_locked = true  # Bật lock để _update giữ position
	
	print("Cutscene1: Boss arrived at ", obj.global_position)
	
	obj.change_animation("idle")
	
	## Đợi một chút
	#await get_tree().create_timer(0.3).timeout
	
	# Trả về time scale bình thường
	Engine.time_scale = 1.0	

func _zoom_camera_out() -> void:
	pass

func _move_player_to_position() -> void:
	if not player or not player_pos:
		print("Warning: Player or PlayerPosCutscene1 not found!")
		await get_tree().create_timer(0.5).timeout
		return
	
	# Player bay tới vị trí
	var player_tween = create_tween()
	player_tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	player_tween.tween_property(player, "global_position", player_pos.global_position, 1.0).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
	await player_tween.finished
	
	print("Cutscene1: Characters in position")

func _show_element_icons() -> void:
	"""Hiển thị icon nguyên tố Thổ (Earth) phóng to lên toàn màn hình rồi mờ dần"""
	
	# Lấy viewport center để spawn icon ở giữa màn hình
	var viewport_size = obj.get_viewport_rect().size
	var center = viewport_size / 2.0
	
	# Cutscene1: Hiển thị hệ Thổ (Earth)
	var sprite = ELEMENT_SPRITE_SCENE.instantiate()
	
	# Set element và load texture
	if not sprite.set_element("earth"):
		print("Warning: Failed to load earth element icon")
		sprite.queue_free()
		return
	
	# Add vào CanvasLayer để hiển thị trên màn hình (không bị ảnh hưởng bởi camera game)
	var canvas_layer = CanvasLayer.new()
	canvas_layer.layer = 100  # Layer cao để hiển thị trên tất cả
	obj.get_tree().root.add_child(canvas_layer)
	canvas_layer.add_child(sprite)
	
	# Đặt vị trí giữa màn hình
	sprite.position = center
	
	# Play effect zoom + fade
	sprite.play_zoom_fade_effect(1.5)
	await sprite.tree_exited  # Chờ sprite tự xóa
	
	# Xóa canvas layer
	canvas_layer.queue_free()
	
	print("Cutscene1: Earth element icon shown")

func _land_player_on_ground() -> void:
	"""Thả player xuống đất (vẫn không cho nhận input)"""
	if not player:
		return
	
	# Bật lại physics để player có thể rơi xuống
	player.set_physics_process(true)
	
	# Đợi cho player chạm đất
	while not player.is_on_floor():
		await get_tree().process_frame
	
	# Tắt physics lại để player đứng yên
	player.set_physics_process(false)
	player.velocity = Vector2.ZERO
	
	print("Cutscene1: Player landed on ground")

func _play_flash_effect() -> void:
	"""Tạo hiệu ứng ánh sáng lóe lên"""
	# Spawn flash effect trong CanvasLayer
	var flash = FADE_BOSS_SCENE.instantiate()
	
	var canvas_layer = CanvasLayer.new()
	canvas_layer.layer = 99  # Layer 99 để hiển thị dưới element sprite (layer 100)
	obj.get_tree().root.add_child(canvas_layer)
	canvas_layer.add_child(flash)
	
	# Play flash effect và đợi nó hoàn thành
	await flash.play_flash_effect(0.8)
	
	# Xóa canvas layer
	canvas_layer.queue_free()
	
	print("Cutscene1: Flash effect completed")

func _physics_process(_delta):
	if not is_instance_valid(obj) or not is_instance_valid(fsm):
		return
	
	if is_boss_locked:
		obj.velocity = Vector2.ZERO
		obj.global_position = boss_locked_position

func _exit() -> void:
	obj.is_stunned = false
	obj.is_movable = true
	obj.set_physics_process(true)  # Bật lại physics khi exit
	is_boss_locked = false
	
	# Re-enable player input và hiện player lại
	if player:
		player.set_physics_process(true)
		player.visible = true
		print("Cutscene1: Player shown again")
	
	# Đảm bảo camera boss bị tắt khi exit
	if boss_camera:
		boss_camera.enabled = false
