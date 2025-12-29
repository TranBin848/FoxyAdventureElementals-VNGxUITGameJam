extends BlackEmperorState

## Cutscene 2: Camera focus boss, boss di chuyển, zoom out, player di chuyển, play animation
## Flow:
## 1. Chuyển camera sang boss camera
## 2. Boss di chuyển tới BossPosCutscene2
## 3. Zoom camera ra toàn cảnh
## 4. Player di chuyển tới PlayerPosCutscene2
## 5. Play animation cutscene2 trong AnimatedBg

var animated_bg: AnimatedSprite2D = null
var player: Player = null
var player_pos: Node2D = null
var boss_pos: Node2D = null
var boss_camera: Camera2D = null
var boss_zone_camera: Camera2D = null
var boss_locked_position: Vector2 = Vector2.ZERO
var is_boss_locked: bool = false

func _enter() -> void:
	print("=== State: Cutscene2 Enter ===")
	
	# Kill tất cả tweens cũ
	var all_tweens = obj.get_tree().get_processed_tweens()
	print("Cutscene2: Killing ", all_tweens.size(), " active tweens")
	for t in all_tweens:
		if t.is_valid():
			t.kill()
	
	# Setup boss
	obj.velocity = Vector2.ZERO
	obj.change_animation("inactive")
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
		boss_pos = pos_container.get_node_or_null("BossPosCutscene2")
		player_pos = pos_container.get_node_or_null("PLayerPosCutscene2")
		
		if player_pos:
			print("Cutscene2: Found PlayerPosCutscene2 at ", player_pos.global_position)
		if boss_pos:
			print("Cutscene2: Found BossPosCutscene2 at ", boss_pos.global_position)
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
	
	# === STEP 2: CHUYỂN SANG CAMERA BOSS ===
	if boss_camera:
		boss_camera.enabled = true
		CameraTransition.transition_camera2D(boss_camera, 1.0)
		await get_tree().create_timer(1.0).timeout
		print("Cutscene2: Camera switched to boss")
	
	# === STEP 3: BOSS DI CHUYỂN TỚI VỊ TRÍ CUTSCENE2 ===
	await _move_boss_to_position()
	
	# === STEP 4: ZOOM CAMERA RA TOÀN CẢNH ===
	await _zoom_camera_out()
	
	# === STEP 5: PLAYER DI CHUYỂN TỚI VỊ TRÍ CUTSCENE2 ===
	await _move_player_to_position()
	
	# === STEP 6: PLAY ANIMATION CUTSCENE2 ===
	if animated_bg:
		print("Cutscene2: Playing AnimatedBg cutscene2")
		animated_bg.play("cutscene2")
		await animated_bg.animation_finished
		print("Cutscene2: AnimatedBg cutscene2 finished")
	
	player.change_animation("dead")
	
	# Đợi một chút trước khi chuyển sang cutscene3
	await get_tree().create_timer(3.0).timeout
	
	# Unlock boss và chuyển sang cutscene3
	is_boss_locked = false
	obj.set_physics_process(true)
	
	if is_instance_valid(fsm) and fsm.states.has("cutscene3"):
		print("Cutscene2: Finished, transitioning to Cutscene3")
		fsm.change_state(fsm.states.cutscene3)
	else:
		print("ERROR: Cannot transition to cutscene3!")

func _move_boss_to_position() -> void:
	if not boss_pos:
		print("Warning: BossPosCutscene2 not found!")
		await get_tree().create_timer(0.5).timeout
		return
	
	var target_pos = boss_pos.global_position
	print("Cutscene2: Moving boss from ", obj.global_position, " to ", target_pos)
	
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
	
	print("Cutscene2: Boss arrived at ", obj.global_position)

func _zoom_camera_out() -> void:
	# Chuyển về boss_zone camera để zoom out toàn cảnh
	if boss_zone_camera:
		print("Cutscene2: Switching to boss_zone camera (zoom out)")
		CameraTransition.transition_camera2D(boss_zone_camera, 1.0)
		await get_tree().create_timer(1.0).timeout

func _move_player_to_position() -> void:
	if not player or not player_pos:
		print("Warning: Player or PlayerPosCutscene2 not found!")
		await get_tree().create_timer(0.5).timeout
		return
	
	print("Cutscene2: Moving player from ", player.global_position, " to ", player_pos.global_position)
	
	# Player di chuyển tới vị trí
	var player_tween = create_tween()
	player_tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	player_tween.tween_property(player, "global_position", player_pos.global_position, 1.2).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
	await player_tween.finished
	
	print("Cutscene2: Player arrived at position")

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
	
	print("Cutscene2: Exit")
