extends BlackEmperorState

## Cutscene 1: Di chuyển player và boss về vị trí cutscene với camera zoom + QTE
## Flow:
## 1-6: Setup positions & Boss Movement
## 7: STANDALONE QTE (No Animation Dependency)
## 8: Element Icons (Earth)
## 9: Play Animation "cutscene1"
## 10-12: Zoom Out, Player Move, Land

# Scene paths
const ELEMENT_SPRITE_PATH = "res://scenes/enemies/final_boss/element_sprite.tscn"
const FADE_BOSS_PATH = "res://scenes/enemies/final_boss/fade_boss_scene.tscn"
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
var qte_keys = [
	{"keyString": "F", "keyCode": KEY_F, "delay": 0.0, "eventDuration": 2.0, "displayDuration": 1.0, "animation_time": 0.0}
]
var qte_results: Array = []
var qte_active: bool = false
var qte_timers: Array = []
var qte_failed: bool = false
var qte_pause_frame: float = -1.0

# Tween management
var active_tweens: Array[Tween] = []

func _enter() -> void:
	print("State: Cutscene1 Enter")
	
	obj.change_animation("idle")
	
	await get_tree().create_timer(0.5).timeout
	
	# Kill only our managed tweens (not CameraTransition's!)
	_kill_active_tweens()
	
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
	
	# Switch to boss_zone camera immediately
	if boss_zone_camera:
		print("Cutscene1: Switching to boss_zone camera")
		CameraTransition.transition_camera2D(boss_zone_camera, 1.5)
	else:
		push_warning("Boss zone camera not found")
	
	await get_tree().create_timer(0.3).timeout
	
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
	Dialogic.start("earth_ultimate")
	await Dialogic.timeline_ended
	
	# === STEP 1: DISABLE PLAYER INPUT ===
	if player and player.fsm:
		if player.fsm.states.has("idle"):
			player.fsm.change_state(player.fsm.states.idle)
		player.set_physics_process(false)
		player.visible = false # Hide player during initial boss move if desired
	
	# === STEP 2: ĐỨNG IM MỘT CHÚT ===
	await get_tree().create_timer(0.5).timeout
	
	# === STEP 3: BOSS BAY LÊN VỊ TRÍ CUTSCENE ===
	await _move_boss_to_position()
	
	# === STEP 7: STANDALONE QTE (NO ANIMATION DEPENDENCY) ===
	print("Cutscene1: Triggering Standalone QTE...")
	
	# 1. Slow Motion immediately
	Engine.time_scale = 0.05
	
	# 2. Start QTE Logic
	_start_qte_sequence()
	
	# 3. Wait for player input
	await qte_sequence_complete
	
	# 4. Cleanup
	_stop_qte_sequence()
	
	# 5. Restore Speed
	print("Cutscene1: Restoring normal time scale")
	Engine.time_scale = 1.0
	
	# 6. Handle Fail
	if qte_failed:
		await _handle_qte_failure()
		return

	print("Cutscene1: QTE Success")

	# === STEP 8: HIỂN THỊ ICON NGUYÊN TỐ ===
	await _show_element_icons()
	
	# === STEP 9: PLAY ANIMATION (NOW THAT QTE IS DONE) ===
	if animated_bg:
		print("Cutscene1: Playing AnimatedBg cutscene1...")
		animated_bg.play("cutscene1")
		await animated_bg.animation_finished
	
	# === STEP 10: ZOOM CAMERA RA ===
	await _zoom_camera_out()
	
	# === STEP 11: PLAYER BAY TỚI VỊ TRÍ ===
	await _move_player_to_position()
	
	# === STEP 12: FLASH EFFECT ===
	await _play_flash_effect()
	
	# === STEP 13: THẢ PLAYER XUỐNG ĐẤT ===
	if player:
		player.visible = true # Ensure player is visible for landing
	await _land_player_on_ground()
	
	await get_tree().create_timer(1.0).timeout
	
	Dialogic.start("earth_ultimate_after")
	await Dialogic.timeline_ended
	
	# === CRITICAL FIX: RESTORE COMBAT STATE ===
	# Unlock boss
	is_boss_locked = false
	obj.set_physics_process(true)
	
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
	
	# Chuyển sang Idle (combat state)
	if is_instance_valid(fsm) and fsm.states.has("standup"):
		print("Cutscene1: Finished successfully, transitioning to combat (standup)")
		fsm.change_state(fsm.states.standup)

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
	
	await get_tree().process_frame
	
	obj.velocity = Vector2.ZERO
	obj.change_animation("moving")
	
	var fly_tween = _create_managed_tween()
	fly_tween.bind_node(obj)
	fly_tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	fly_tween.tween_property(obj, "global_position", target_pos, 1.2).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN_OUT)
	
	await fly_tween.finished
	_remove_tween(fly_tween)
	
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
	
	player.set_physics_process(false)
	var gravity = 980.0
	
	while not player.is_on_floor():
		var delta = obj.get_physics_process_delta_time()
		player.velocity.y += gravity * delta
		player.move_and_slide()
		await obj.get_tree().physics_frame
	
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
		player.is_invulnerable = false
	
	await get_tree().create_timer(1.0, true, false, true).timeout
	
	Engine.time_scale = 1.0
	if animated_bg: animated_bg.speed_scale = 1.0
	
	# Show UI before killing player
	if canvas_layer: canvas_layer.visible = true
	if ui: ui.visible = true
	
	# Re-enable physics processing so dead state can run
	if player:
		player.set_physics_process(true)
	
	# Kill player
	if GameManager and GameManager.player:
		player.fsm.current_state.take_damage(Vector2.ZERO, 99999)

func _physics_process(_delta):
	if not is_instance_valid(obj) or not is_instance_valid(fsm): return
	if is_boss_locked:
		obj.velocity = Vector2.ZERO
		obj.global_position = boss_locked_position

# ==============================================================================
#  TWEEN MANAGEMENT
# ==============================================================================

func _create_managed_tween() -> Tween:
	var tween = get_tree().create_tween()
	active_tweens.append(tween)
	return tween

func _remove_tween(tween: Tween) -> void:
	var idx = active_tweens.find(tween)
	if idx != -1:
		active_tweens.remove_at(idx)

func _kill_active_tweens() -> void:
	for tween in active_tweens:
		if is_instance_valid(tween) and tween.is_valid():
			tween.kill()
	active_tweens.clear()

func _exit() -> void:
	_kill_active_tweens()
	
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
