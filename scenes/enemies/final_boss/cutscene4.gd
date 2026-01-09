extends BlackEmperorState

## Cutscene 4: Zoom boss, di chuyển, zoom ra, player di chuyển, QTE -> Water Icon -> Animation
## Flow:
## 1. Zoom vào boss camera
## 2. Boss di chuyển tới BossPosCutscene4
## 3. Zoom ra (boss_zone camera)
## 4. Player di chuyển tới PlayerPosCutscene4
## 5. STANDALONE QTE (Key R) -> Slow Motion -> Success/Fail
## 6. Hiển thị icon nguyên tố Kim (Water)
## 7. Play animation "cutscene4"
## 8. Transition to Combat (Idle State)

# Scene
const ELEMENT_SPRITE_SCENE = preload("res://scenes/enemies/final_boss/element_sprite.tscn")
const QTE_PATH = "res://scenes/ui/popup/quick_time_event.tscn"

# Signal to break the await immediately when QTE is done
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
# Config for Water Element QTE (Key R)
var qte_keys = [
	{"keyString": "F", "keyCode": KEY_F, "delay": 0.0, "eventDuration": 2.0, "displayDuration": 1.0}
]
var qte_results: Array = []
var qte_active: bool = false
var qte_timers: Array = []
var qte_failed: bool = false

func _enter() -> void:
	print("=== State: Cutscene4 Enter ===")
	
	obj.change_animation("idle")
	
	# Kill all active tweens
	var all_tweens = obj.get_tree().get_processed_tweens()
	for t in all_tweens:
		if t.is_valid(): t.kill()
	
	# Setup boss
	obj.velocity = Vector2.ZERO
	obj.change_animation("inactive")
	obj.is_stunned = true
	obj.is_movable = false
	obj.set_physics_process(false)
	is_boss_locked = false
	
	# Find AnimatedBg
	if animated_bg == null:
		animated_bg = obj.get_tree().get_first_node_in_group("animated_bg")
	
	# Find and hide UI
	if canvas_layer == null:
		canvas_layer = obj.get_tree().root.find_child("GUI", true, false) as CanvasLayer
		if canvas_layer:
			canvas_layer.visible = false
			if ui: ui.visible = false
	
	# Find Position Nodes
	var pos_container = obj.get_tree().root.find_child("PosBossPlayer", true, false)
	if pos_container:
		boss_pos = pos_container.get_node_or_null("BossPosCutscene4")
		player_pos = pos_container.get_node_or_null("PLayerPosCutscene4")
	else:
		print("Warning: PosBossPlayer container not found")
	
	# Find Player
	if player == null:
		player = obj.get_tree().root.find_child("Player", true, false) as Player
	
	# Find Cameras
	if boss_camera == null:
		boss_camera = obj.get_node_or_null("Camera2D")
	
	if boss_zone_camera == null and obj.boss_zone:
		boss_zone_camera = obj.boss_zone.camera_2d
	
	# Disable player input
	if player and player.fsm:
		if player.fsm.states.has("idle"):
			player.fsm.change_state(player.fsm.states.idle)
		player.set_physics_process(false)
	
	# Setup QTE
	_setup_qte_container()
	
	# Start Sequence
	_start_cutscene_sequence()

func _setup_qte_container() -> void:
	qte_container = Control.new()
	qte_container.name = "QTE_Container_C4"
	qte_container.set_anchors_preset(Control.PRESET_FULL_RECT)
	qte_container.mouse_filter = Control.MOUSE_FILTER_IGNORE
	
	var canvas = CanvasLayer.new()
	canvas.layer = 100
	canvas.name = "QTE_CanvasLayer_C4"
	obj.get_tree().root.add_child(canvas)
	canvas.add_child(qte_container)

func _start_cutscene_sequence() -> void:
	# === STEP 1: ZOOM VÀO BOSS CAMERA ===
	if boss_camera:
		boss_camera.enabled = true
		CameraTransition.transition_camera2D(boss_camera, 1.0)
		await get_tree().create_timer(1.0).timeout

	
	# === STEP 5: STANDALONE QTE (NO ANIMATION DEPENDENCY) ===
	print("Cutscene4: Triggering Standalone QTE...")
	
	# 1. Slow Motion immediately
	Engine.time_scale = 0.05
	
	# 2. Start QTE Logic
	_start_qte_sequence()
	
	# 3. Wait for Input
	await qte_sequence_complete
	
	# 4. Cleanup
	_stop_qte_sequence()
	
	# 5. Restore Speed
	print("Cutscene4: Restoring normal time scale")
	Engine.time_scale = 1.0
	
	# 6. Handle Fail
	if qte_failed:
		await _handle_qte_failure()
		return

	print("Cutscene4: QTE Success")

	# === STEP 6: HIỂN THỊ ICON NGUYÊN TỐ KIM (Water) ===
	await _show_element_icons()
		
	# === STEP 2: BOSS DI CHUYỂN TỚI VỊ TRÍ CUTSCENE4 ===
	await _move_boss_to_position()
	
	# === STEP 3: ZOOM RA (BOSS_ZONE CAMERA) ===
	if boss_zone_camera:
		print("Cutscene4: Switching to boss_zone camera (zoom out)")
		CameraTransition.transition_camera2D(boss_zone_camera, 1.0)
		await get_tree().create_timer(1.0).timeout
	
	# === STEP 4: PLAYER DI CHUYỂN TỚI VỊ TRÍ CUTSCENE4 ===
	await _move_player_to_position()
	
	# === STEP 7: PLAY ANIMATION (NOW THAT QTE IS DONE) ===
	if animated_bg:
		print("Cutscene4: Playing AnimatedBg cutscene4...")
		animated_bg.play("cutscene4")
		await animated_bg.animation_finished
		print("Cutscene4: AnimatedBg cutscene4 finished")
	
	# Đợi một chút
	await get_tree().create_timer(1.0).timeout
	
	# === CRITICAL FIX: RESTORE COMBAT STATE ===
	# Unlock boss
	obj.set_physics_process(true)
	is_boss_locked = false
	
	# Re-enable hurtbox so boss can take damage again
	if obj.has_method("enable_hurtbox"):
		obj.enable_hurtbox()
	
	# Show UI again
	if canvas_layer:
		canvas_layer.visible = true
	if ui:
		ui.visible = true
	
	# Return boss to combat phase (FLY)
	obj.current_phase = obj.Phase.FLY
	
	# Re-enable player
	if player:
		player.set_physics_process(true)
		player.visible = true
	
	# Transition to Idle (combat state)
	if is_instance_valid(fsm) and fsm.states.has("standup"):
		print("Cutscene4: Finished successfully, transitioning to combat (standup)")
		fsm.change_state(fsm.states.standup)
	else:
		print("ERROR: Cannot transition to idle!")

# ============= QTE FUNCTIONS =============

func _start_qte_sequence() -> void:
	qte_active = true
	qte_results.clear()
	qte_timers.clear()
	qte_failed = false
	
	print("Cutscene4: QTE sequence started with ", qte_keys.size(), " keys")
	
	for i in range(qte_keys.size()):
		var key_data = qte_keys[i]
		var delay = key_data.delay
		
		if delay <= 0.05:
			_spawn_qte_key(i)
			continue

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
	if qte_container and qte_container.get_parent():
		qte_container.get_parent().queue_free()
	qte_active = false
	for timer in qte_timers:
		if is_instance_valid(timer):
			timer.stop()
			timer.queue_free()
	qte_timers.clear()
	print("Cutscene4: QTE sequence stopped")

func _spawn_qte_key(index: int) -> void:
	if not qte_active or index >= qte_keys.size(): return
	
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
	
	print("Cutscene4: Spawned QTE key #", index)

func _on_qte_key_finished(success: bool) -> void:
	qte_results.append(success)
	print("Cutscene4: QTE key ", "SUCCESS" if success else "FAILED")
	
	if not success:
		qte_failed = true
		print("Cutscene4: QTE FAILURE DETECTED")
		qte_sequence_complete.emit()
		return
	
	if qte_results.size() >= qte_keys.size():
		print("Cutscene4: All QTE keys completed")
		qte_sequence_complete.emit()

func _handle_qte_failure() -> void:
	print("Cutscene4: Handling QTE failure")
	Engine.time_scale = 0.0
	
	await get_tree().create_timer(1.0, true, false, true).timeout 
	
	Engine.time_scale = 1.0
	if animated_bg: animated_bg.speed_scale = 1.0
	
	# Show UI before killing player
	if canvas_layer: canvas_layer.visible = true
	if ui: ui.visible = true
	
	# Kill player
	if GameManager and GameManager.player:
		player.take_damage(99999)

	# === CRITICAL FIX: RESTORE COMBAT STATE ===
	obj.set_physics_process(true)
	is_boss_locked = false
	
	# Re-enable hurtbox
	if obj.has_method("enable_hurtbox"):
		obj.enable_hurtbox()
	
	# Reset boss phase to combat (FLY)
	obj.current_phase = obj.Phase.FLY
	
	# Transition to Idle (Combat)
	if is_instance_valid(fsm) and fsm.states.has("idle"):
		print("Cutscene4: QTE Failed, transitioning to combat (idle)")
		fsm.change_state(fsm.states.idle)

# ============= MOVEMENT & VISUAL FUNCTIONS =============

func _move_boss_to_position() -> void:
	if not boss_pos: return
	
	var target_pos = boss_pos.global_position
	obj.velocity = Vector2.ZERO
	
	var fly_tween = obj.get_tree().create_tween()
	fly_tween.bind_node(obj)
	fly_tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	fly_tween.tween_property(obj, "global_position", target_pos, 1.5).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN_OUT)
	
	await fly_tween.finished
	
	obj.global_position = target_pos
	boss_locked_position = target_pos
	is_boss_locked = true

func _move_player_to_position() -> void:
	if not player or not player_pos: return
	
	var player_tween = create_tween()
	player_tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	player_tween.tween_property(player, "global_position", player_pos.global_position, 1.2).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
	await player_tween.finished

func _show_element_icons() -> void:
	"""Hiển thị icon nguyên tố Kim (Water) phóng to lên toàn màn hình rồi mờ dần"""
	var viewport_size = obj.get_viewport_rect().size
	var center = viewport_size / 2.0
	
	var sprite = ELEMENT_SPRITE_SCENE.instantiate()
	
	# Updated to "Water"
	if not sprite.set_element("water"):
		print("Warning: Failed to load Water element icon")
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
	
	if player:
		player.set_physics_process(true)
		player.visible = true
	
	if boss_camera:
		boss_camera.enabled = false
	
	# Ensure hurtbox is enabled when exiting
	if obj.has_method("enable_hurtbox"):
		obj.enable_hurtbox()
	
	print("Cutscene4: Exit")
