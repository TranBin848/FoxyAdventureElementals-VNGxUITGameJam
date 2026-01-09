extends BlackEmperorState

## Cutscene 1: Di chuyển player và boss về vị trí cutscene với camera zoom + QTE
## Flow:
## 1-9: Setup positions
## 10: QTE sequence (Fixed: Immediate end on input, correct time scaling)
## 11: Flash effect
## 12: Land player (Fixed: Manual gravity loop)

# Scene paths
const ELEMENT_SPRITE_PATH = "res://scenes/enemies/final_boss/element_sprite.tscn"
const FADE_BOSS_PATH = "res://scenes/enemies/final_boss/fade_boss_scene.tscn"
const QTE_PATH = "res://scenes/ui/popup/quick_time_event.tscn"

# ✅ ADDED: Signal to break the await immediately when QTE is done
signal qte_sequence_complete

var animated_bg: AnimationPlayer = null
var player: Player = null
var player_pos: Node2D = null
var boss_pos: Node2D = null
var boss_camera: Camera2D = null
var boss_zone_camera: Camera2D = null
var boss_locked_position: Vector2 = Vector2.ZERO
var is_boss_locked: bool = false
var canvas_layer: CanvasLayer = null
@onready var ui: CanvasLayer = $"../../UI"

# QTE Variables
var qte_container: Control = null
var qte_keys = [
	{"keyString": "F", "keyCode": KEY_F, "delay": 0.0, "eventDuration": 2.0, "displayDuration": 1.0, "animation_time": 0.0}
]
var qte_results: Array = []
var qte_active: bool = false
var qte_timers: Array = []
var qte_failed: bool = false
var qte_pause_frame: float = -1.0

func _enter() -> void:
	print("State: Cutscene1 Enter")
	
	obj.change_animation("idle")
	
	await get_tree().create_timer(0.5).timeout
	
	# KILL TẤT CẢ TWEENS từ state cũ
	var all_tweens = obj.get_tree().get_processed_tweens()
	for t in all_tweens:
		if t.is_valid():
			t.kill()
	
	# Force đặt lại position
	obj.velocity = Vector2.ZERO
	obj.is_stunned = true
	obj.is_movable = false
	obj.set_physics_process(false)
	is_boss_locked = false
	
	# Tìm AnimatedBg
	if animated_bg == null:
		animated_bg = obj.get_tree().get_first_node_in_group("animated_bg")
	
	# Tìm và ẩn CanvasLayer UI
	if canvas_layer == null:
		canvas_layer = obj.get_tree().root.find_child("GUI", true, false) as CanvasLayer
		if canvas_layer:
			canvas_layer.visible = false
			ui.visible = false
	
	# Tìm position nodes
	var pos_container = obj.get_tree().root.find_child("PosBossPlayer", true, false)
	if pos_container:
		boss_pos = pos_container.get_node_or_null("BossPosCutscene1")
		player_pos = pos_container.get_node_or_null("PLayerPosCutscene1")		
	
	# Tìm player
	if player == null:
		player = GameManager.player as Player
	
	# Tìm cameras
	if boss_camera == null:
		boss_camera = obj.get_node_or_null("Camera2D")
	
	if boss_zone_camera == null and obj.boss_zone:
		boss_zone_camera = obj.boss_zone.camera_2d
	
	# Setup QTE container
	_setup_qte_container()
	
	# Bắt đầu sequence
	_start_cutscene_sequence()

func _setup_qte_container() -> void:
	qte_container = Control.new()
	qte_container.name = "QTE_Container"
	qte_container.set_anchors_preset(Control.PRESET_FULL_RECT)
	qte_container.mouse_filter = Control.MOUSE_FILTER_IGNORE
	
	var canvas = CanvasLayer.new()
	canvas.layer = 100
	canvas.name = "QTE_CanvasLayer"
	obj.get_tree().root.add_child(canvas)
	canvas.add_child(qte_container)

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
		boss_camera.enabled = true
		CameraTransition.transition_camera2D(boss_camera, 1.0)
		await get_tree().create_timer(1.0).timeout
	
	# === STEP 4: ZOOM CAMERA BOSS VÀO ===
	await _zoom_boss_camera_in()
	
	# === STEP 5: BOSS BAY LÊN VỊ TRÍ CUTSCENE ===
	await _move_boss_to_position()
	
	# === STEP 6: CHUYỂN LẠI CAMERA BOSS_ZONE ===
	if boss_zone_camera:
		CameraTransition.transition_camera2D(boss_zone_camera, 1.0)
		await get_tree().create_timer(1.0).timeout
	
	# === STEP 7: HIỂN THỊ ICON NGUYÊN TỐ ===
	await _show_element_icons()
	
	# === STEP 8: ZOOM CAMERA RA ===
	await _zoom_camera_out()
	
	# === STEP 9: PLAYER BAY TỚI VỊ TRÍ ===
	await _move_player_to_position()
	
	# === STEP 10: BẮT ĐẦU ANIMATION + QTE SEQUENCE ===
	if animated_bg:
		print("Cutscene1: Triggering AnimatedBg...")
		
		if player:
			player.visible = false
		
		# 1. Start the animation normally
		animated_bg.play("cutscene1")
		
		# 2. ✅ WAIT FOR THE SIGNAL FROM THE ANIMATION TRACK
		# The code now pauses here until the animation timeline hits the "anim_trigger_qte" keyframe.
		print("Cutscene1: Waiting for animation trigger...")
		await animated_bg.qte_trigger_moment
		
		# 3. The exact frame has been hit. Apply Slow Motion immediately.
		print("Cutscene1: Trigger received! Slowing down...")
		Engine.time_scale = 0.05 # Very slow motion for dramatic effect
		
		# 4. Start QTE Logic
		_start_qte_sequence()
		
		# 5. Wait for player input (Success/Fail signal)
		await qte_sequence_complete
		
		# 6. Cleanup
		_stop_qte_sequence()
		
		# 7. Restore Speed immediately
		print("Cutscene1: Restoring normal time scale")
		Engine.time_scale = 1.0
		
		# 8. Handle Fail/Continue logic
		if qte_failed:
			# Pause immediately at the failure point
			animated_bg.pause() 
			await _handle_qte_failure()
			return 
		
		# Success logic...
		print("Cutscene1: QTE Success")
		if animated_bg.is_playing():
			await animated_bg.animation_finished
	
	# === STEP 11: FLASH EFFECT ===
	await _play_flash_effect()
	
	# === STEP 12: THẢ PLAYER XUỐNG ĐẤT (FIXED) ===
	await _land_player_on_ground()
	
	await get_tree().create_timer(1.0).timeout
	
	# Unlock boss
	is_boss_locked = false
	obj.set_physics_process(true)
	
	# Chuyển sang Cutscene2
	if is_instance_valid(fsm) and fsm.states.has("cutscene2"):
		print("Cutscene1: Finished, transitioning to Cutscene2")
		fsm.change_state(fsm.states.cutscene2)

# ============= QTE FUNCTIONS =============

func _start_qte_sequence() -> void:
	"""Bắt đầu spawn QTE events"""
	qte_active = true
	qte_results.clear()
	qte_timers.clear()
	qte_failed = false
	
	print("Cutscene1: QTE sequence started with ", qte_keys.size(), " keys")
	
	for i in range(qte_keys.size()):
		var key_data = qte_keys[i]
		var delay = key_data.delay
		
		# ✅ FIX 1: If delay is effectively zero, spawn IMMEDIATELY.
		# Do not create a Timer for instantaneous events when time_scale is modified.
		if delay <= 0.05:
			_spawn_qte_key(i)
			continue

		# ✅ FIX 2: If we must wait, scale the delay down.
		# If time_scale is 0.1 (10% speed), a 2.0s real-world delay 
		# needs to be 0.2s game-time to finish in 2 real seconds.
		var adjusted_delay = delay * Engine.time_scale
		
		var timer = Timer.new()
		timer.name = "QTE_Timer_%d" % i
		timer.wait_time = adjusted_delay
		timer.one_shot = true
		
		var key_index = i
		timer.timeout.connect(func(): _spawn_qte_key(key_index))
		
		qte_container.add_child(timer)
		qte_timers.append(timer)
		timer.start()

func _stop_qte_sequence() -> void:
	qte_active = false
	for timer in qte_timers:
		if is_instance_valid(timer):
			timer.stop()
			timer.queue_free()
	qte_timers.clear()
	print("Cutscene1: QTE sequence stopped")

func _spawn_qte_key(index: int) -> void:
	if not qte_active or index >= qte_keys.size():
		return
	
	var key_data = qte_keys[index]
	var qte_node = load(QTE_PATH).instantiate()
	
	qte_node.keyCode = key_data.keyCode
	qte_node.keyString = key_data.keyString
	
	if key_data.has("eventDuration"):
		qte_node.eventDuration = key_data.eventDuration
	if key_data.has("displayDuration"):
		qte_node.displayDuration = key_data.displayDuration
	
	qte_node.finished.connect(_on_qte_key_finished)
	qte_container.add_child(qte_node)
	
	print("Cutscene1: Spawned QTE key #", index)

func _on_qte_key_finished(success: bool) -> void:
	qte_results.append(success)
	print("Cutscene1: QTE key ", "SUCCESS" if success else "FAILED")
	
	# Case 1: Fail -> End Immediately
	if not success:
		qte_failed = true
		print("Cutscene1: QTE FAILURE DETECTED - Emitting completion signal")
		qte_sequence_complete.emit()
		return
	
	# Case 2: Success -> Check if all keys done
	if qte_results.size() >= qte_keys.size():
		print("Cutscene1: All QTE keys completed - Emitting completion signal")
		qte_sequence_complete.emit()

func _get_qte_success_rate() -> String:
	if qte_results.is_empty(): return "No QTEs"
	var successes = qte_results.filter(func(x): return x).size()
	return "%d/%d" % [successes, qte_results.size()]

# ============= MOVEMENT & EFFECTS FUNCTIONS =============

func _zoom_boss_camera_in() -> void:
	Engine.time_scale = 0.4

func _move_boss_to_position() -> void:
	if not boss_pos: return
	
	var target_pos = boss_pos.global_position
	var all_tweens = obj.get_tree().get_processed_tweens()
	for t in all_tweens:
		if t.is_valid(): t.kill()
	
	await get_tree().process_frame
	
	obj.velocity = Vector2.ZERO
	obj.change_animation("moving")
	
	var fly_tween = obj.get_tree().create_tween()
	fly_tween.bind_node(obj)
	fly_tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	fly_tween.tween_property(obj, "global_position", target_pos, 1.2).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN_OUT)
	
	await fly_tween.finished
	
	obj.global_position = target_pos
	boss_locked_position = target_pos
	is_boss_locked = true
	
	obj.change_animation("idle")
	Engine.time_scale = 1.0	

func _zoom_camera_out() -> void:
	pass

func _move_player_to_position() -> void:
	if not player or not player_pos: return
	
	var player_tween = create_tween()
	player_tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	player_tween.tween_property(player, "global_position", player_pos.global_position, 1.0).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
	await player_tween.finished

func _show_element_icons() -> void:
	var viewport_size = obj.get_viewport_rect().size
	var center = viewport_size / 2.0
	
	var sprite = load(ELEMENT_SPRITE_PATH).instantiate()
	if not sprite.set_element("earth"):
		sprite.queue_free()
		return
	
	var canvas = CanvasLayer.new()
	canvas.layer = 100
	obj.get_tree().root.add_child(canvas)
	canvas.add_child(sprite)
	
	sprite.position = center
	sprite.play_zoom_fade_effect(1.5)
	await sprite.tree_exited
	canvas.queue_free()


func _land_player_on_ground() -> void:
	if not player: return
	
	print("Cutscene1: Landing player...")
	
	# ✅ FIXED: Manually apply gravity loop until collision
	# We do NOT rely on player.set_physics_process(true) alone because
	# the idle state might not apply gravity if there is no input.
	
	# Ensure physics is off so we can control it manually
	player.set_physics_process(false) 
	
	var gravity = 980.0
	
	# Loop until we hit the floor
	while not player.is_on_floor():
		var delta = obj.get_physics_process_delta_time()
		
		# Apply simple gravity
		player.velocity.y += gravity * delta
		player.move_and_slide()
		
		# Wait for next physics frame
		await obj.get_tree().physics_frame
	
	# Reset state once grounded
	player.velocity = Vector2.ZERO
	print("Cutscene1: Player landed successfully")

func _play_flash_effect() -> void:
	var flash = load(FADE_BOSS_PATH).instantiate()
	var canvas = CanvasLayer.new()
	canvas.layer = 99
	obj.get_tree().root.add_child(canvas)
	canvas.add_child(flash)
	
	await flash.play_flash_effect(0.8)
	canvas.queue_free()

func _handle_qte_failure() -> void:
	print("Cutscene1: Handling QTE failure")
	Engine.time_scale = 0.0 # Pause
	
	if player:
		player.visible = true
		player.set_physics_process(false)
	
	# Wait 1 real second
	await get_tree().create_timer(1.0, true, false, true).timeout 
	
	Engine.time_scale = 1.0
	if animated_bg: animated_bg.speed_scale = 1.0
	
	if canvas_layer: canvas_layer.visible = true
	if ui: ui.visible = true
	
	# Kill player
	if GameManager and GameManager.player:
		player.take_damage(99999)

	is_boss_locked = false
	obj.set_physics_process(true)
	
	if is_instance_valid(fsm) and fsm.states.has("idle"):
		fsm.change_state(fsm.states.idle)

func _physics_process(_delta):
	if not is_instance_valid(obj) or not is_instance_valid(fsm): return
	if is_boss_locked:
		obj.velocity = Vector2.ZERO
		obj.global_position = boss_locked_position

func _exit() -> void:
	obj.is_stunned = false
	obj.is_movable = true
	obj.set_physics_process(true)
	is_boss_locked = false
	
	_stop_qte_sequence()
	if qte_container and qte_container.get_parent():
		qte_container.get_parent().queue_free()
	
	if player:
		player.set_physics_process(true)
		player.visible = true
	
	if boss_camera:
		boss_camera.enabled = false
