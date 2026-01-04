extends BlackEmperorState

## Cutscene 4: Zoom boss, di chuyển, zoom ra, player di chuyển, hiển thị metal element, play animation
## Flow:
## 1. Zoom vào boss camera
## 2. Boss di chuyển tới BossPosCutscene5
## 3. Zoom ra (boss_zone camera)
## 4. Player di chuyển tới PlayerPosCutscene5
## 5. Hiển thị icon nguyên tố Kim (Metal)
## 6. Play animation cutscene5
## 7. Sau khi xong sẽ trigger boss mất 1/3 máu và chuyển phase

# Scene
const ELEMENT_SPRITE_SCENE = preload("res://scenes/enemies/final_boss/element_sprite.tscn")

var animated_bg: AnimatedSprite2D = null
var player: Player = null
var player_pos: Node2D = null
var boss_pos: Node2D = null
var boss_camera: Camera2D = null
var boss_zone_camera: Camera2D = null
var boss_locked_position: Vector2 = Vector2.ZERO
var is_boss_locked: bool = false
var canvas_layer: CanvasLayer = null  # CanvasLayer UI cần bật lại

func _enter() -> void:
	print("=== State: Cutscene6 Enter ===")
	
	obj.change_animation("idle")
	
	# Kill tất cả tweens cũ
	var all_tweens = obj.get_tree().get_processed_tweens()
	print("Cutscene6: Killing ", all_tweens.size(), " active tweens")
	for t in all_tweens:
		if t.is_valid():
			t.kill()
	
	# Setup boss
	obj.velocity = Vector2.ZERO
	obj.is_stunned = true
	obj.is_movable = false
	obj.set_physics_process(false)
	is_boss_locked = false
	
	# Tìm AnimatedBg
	if animated_bg == null:
		animated_bg = obj.get_tree().get_first_node_in_group("animated_bg")
	
	# Tìm position nodes
	var pos_container = obj.get_tree().root.find_child("PosBossPlayer", true, false)
	if pos_container:
		boss_pos = pos_container.get_node_or_null("BossPosCutscene5")
		player_pos = pos_container.get_node_or_null("PLayerPosCutscene5")
		
		if player_pos:
			print("Cutscene5: Found PlayerPosCutscene5 at ", player_pos.global_position)
		if boss_pos:
			print("Cutscene5: Found BossPosCutscene5 at ", boss_pos.global_position)
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
	
	# === STEP 2: ZOOM VÀO BOSS CAMERA ===
	if boss_camera:
		boss_camera.enabled = true
		CameraTransition.transition_camera2D(boss_camera, 1.0)
		await get_tree().create_timer(1.0).timeout
		print("Cutscene6: Camera zoomed to boss")
	
	# === STEP 3: BOSS DI CHUYỂN TỚI VỊ TRÍ CUTSCENE5 ===
	await _move_boss_to_position()
	
	# === STEP 4: ZOOM RA (BOSS_ZONE CAMERA) ===
	if boss_zone_camera:
		print("Cutscene6: Switching to boss_zone camera (zoom out)")
		CameraTransition.transition_camera2D(boss_zone_camera, 1.0)
		await get_tree().create_timer(1.0).timeout
	
	# === STEP 5: PLAYER DI CHUYỂN TỚI VỊ TRÍ CUTSCENE5 ===
	await _move_player_to_position()
	
	# === STEP 6: HIỂN THỊ ICON NGUYÊN TỐ KIM (METAL) ===
	await _show_element_icons()
	
	# === STEP 7: PLAY ANIMATION CUTSCENE5 ===
	if animated_bg:
		print("Cutscene6: Playing AnimatedBg cutscene6")
		animated_bg.play("cutscene6")
		await animated_bg.animation_finished
		print("Cutscene5: AnimatedBg cutscene6 finished")
	
	# Đợi một chút
	await get_tree().create_timer(1.0).timeout
	
	obj.set_physics_process(true)
	
	if is_instance_valid(fsm) and fsm.states.has("cutscene6"):
		print("Cutscene5: Finished, transitioning to Cutscene6")
		fsm.change_state(fsm.states.cutscene6)
	else:
		print("ERROR: Cannot transition to cutscene5!")
	
	## === STEP 8: KẾT THÚC CUTSCENES - TRIGGER BOSS MẤT MÁU ===
	#print("Cutscene5: All cutscenes complete - Emitting signal")
	#if animated_bg:
		#animated_bg.all_cutscenes_finished.emit()

func _move_boss_to_position() -> void:
	if not boss_pos:
		print("Warning: BossPosCutscene5 not found!")
		await get_tree().create_timer(0.5).timeout
		return
	
	var target_pos = boss_pos.global_position
	print("Cutscene5: Moving boss from ", obj.global_position, " to ", target_pos)
	
	# Disable velocity
	obj.velocity = Vector2.ZERO
	
	# Tạo tween
	var fly_tween = obj.get_tree().create_tween()
	fly_tween.bind_node(obj)
	fly_tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	fly_tween.tween_property(obj, "global_position", target_pos, 1.5).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN_OUT)
	
	await fly_tween.finished
	
	# Lock position
	obj.global_position = target_pos
	boss_locked_position = target_pos
	is_boss_locked = true
	
	print("Cutscene5: Boss arrived at ", obj.global_position)

func _move_player_to_position() -> void:
	if not player or not player_pos:
		print("Warning: Player or PlayerPosCutscene5 not found!")
		await get_tree().create_timer(0.5).timeout
		return
	
	print("Cutscene5: Moving player from ", player.global_position, " to ", player_pos.global_position)
	
	# Player di chuyển tới vị trí
	var player_tween = create_tween()
	player_tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	player_tween.tween_property(player, "global_position", player_pos.global_position, 1.2).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
	await player_tween.finished
	
	print("Cutscene5: Player arrived at position")

func _show_element_icons() -> void:
	"""Hiển thị icon nguyên tố Kim (Metal) phóng to lên toàn màn hình rồi mờ dần"""
	
	# Lấy viewport center để spawn icon ở giữa màn hình
	var viewport_size = obj.get_viewport_rect().size
	var center = viewport_size / 2.0
	
	# Cutscene5: Hiển thị hệ Kim (Metal)
	var sprite = ELEMENT_SPRITE_SCENE.instantiate()
	
	# Set element và load texture
	if not sprite.set_element("wood"):
		print("Warning: Failed to load metal element icon")
		sprite.queue_free()
		return
	
	# Add vào CanvasLayer để hiển thị trên màn hình
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
	
	print("Cutscene5: Metal element icon shown")

func _physics_process(_delta):
	if not is_instance_valid(obj) or not is_instance_valid(fsm):
		return
	
	if is_boss_locked:
		obj.velocity = Vector2.ZERO
		obj.global_position = boss_locked_position

func _exit() -> void:
	obj.is_stunned = false
	obj.is_movable = true
	obj.set_physics_process(true)
	is_boss_locked = false
	
	# Re-enable player input
	if player:
		player.set_physics_process(true)
	
	# Tắt boss camera
	if boss_camera:
		boss_camera.enabled = false
	
	# Bật lại CanvasLayer UI
	if canvas_layer == null:
		canvas_layer = obj.get_tree().root.find_child("GUI", true, false) as CanvasLayer
	if canvas_layer:
		print("Cutscene5: Showing CanvasLayer again")
		canvas_layer.visible = true
	
	print("Cutscene5: Exit")
