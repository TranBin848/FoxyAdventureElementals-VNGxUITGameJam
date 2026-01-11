extends BlackEmperorState

## Cutscene 3: Parallel Move, QTE -> Fire Icon -> Animation -> Transition
## Flow:
## 1. Setup & Disable Input
## 2. START PARALLEL: Boss Knockback + Player Move + Animation Loop
## 3. STANDALONE QTE (Key E) -> Slow Motion -> Success/Fail
## 4. Element Icon (Fire)
## 5. Wait for Animation Finish
## 6. Flash Effect -> Land Player -> Transition

# Scene
const ELEMENT_SPRITE_SCENE = preload("res://scenes/enemies/final_boss/element_sprite.tscn")
const FADE_BOSS_SCENE = preload("res://scenes/enemies/final_boss/fade_boss_scene.tscn")
const QTE_PATH = "res://scenes/ui/popup/quick_time_event.tscn"

# Signal to break the await immediately when QTE is done
signal qte_sequence_complete

var animated_bg: AnimationPlayer = null
var player: Player = null
var player_pos: Node2D = null
var boss_pos: Node2D = null
var boss_zone_camera: Camera2D = null
var canvas_layer: CanvasLayer = null
@onready var ui: CanvasLayer = $"../../UI"

# QTE Variables
var qte_container: Control = null
# Config for Fire Element QTE (Key E)
var qte_keys = [
	{"keyString": "F", "keyCode": KEY_F, "delay": 0.0, "eventDuration": 2.0, "displayDuration": 1.0}
]
var qte_results: Array = []
var qte_active: bool = false
var qte_timers: Array = []
var qte_failed: bool = false

# Tween management
var active_tweens: Array[Tween] = []

func _enter() -> void:
	print("=== State: Cutscene3 Enter ===")
	
	obj.change_animation("idle")
	
	# Kill only our managed tweens (not CameraTransition's!)
	_kill_active_tweens()
	
	# Setup boss
	obj.velocity = Vector2.ZERO
	obj.change_animation("inactive")
	obj.is_stunned = true
	obj.is_movable = false
	obj.set_physics_process(false)
	
	# Tìm AnimatedBg
	if animated_bg == null:
		animated_bg = obj.get_tree().get_first_node_in_group("animated_bg")
	
	# Tìm và ẩn UI
	if canvas_layer == null:
		canvas_layer = obj.get_tree().root.find_child("GUI", true, false) as CanvasLayer
		if canvas_layer:
			canvas_layer.visible = false
			if ui: ui.visible = false
	
	# Tìm player
	if player == null:
		player = obj.get_tree().root.find_child("Player", true, false) as Player
	
	# Tìm camera
	if boss_zone_camera == null and obj.boss_zone:
		boss_zone_camera = obj.boss_zone.camera_2d
	
	# Switch to boss_zone camera immediately
	if boss_zone_camera:
		print("Cutscene3: Switching to boss_zone camera")
		CameraTransition.transition_camera2D(boss_zone_camera, 1.5)
	else:
		push_warning("Boss zone camera not found")
	
	await get_tree().create_timer(0.3).timeout
	
	# Tìm position nodes
	var pos_container = obj.get_tree().root.find_child("PosBossPlayer", true, false)
	if pos_container:
		boss_pos = pos_container.get_node_or_null("BossPosCutscene3")
		player_pos = pos_container.get_node_or_null("PLayerPosCutscene3")
	else:
		print("Warning: PosBossPlayer container not found")
	
	# Setup QTE
	_setup_qte_container()
	
	# Bắt đầu sequence
	_start_cutscene_sequence()

func _setup_qte_container() -> void:
	qte_container = Control.new()
	qte_container.name = "QTE_Container_C3"
	qte_container.set_anchors_preset(Control.PRESET_FULL_RECT)
	qte_container.mouse_filter = Control.MOUSE_FILTER_IGNORE
	
	var canvas = CanvasLayer.new()
	canvas.layer = 100
	canvas.name = "QTE_CanvasLayer_C3"
	obj.get_tree().root.add_child(canvas)
	canvas.add_child(qte_container)

func _start_cutscene_sequence() -> void:
	# === STEP 1: DISABLE INPUT ===
	if player and player.fsm:
		if player.fsm.states.has("idle"):
			player.fsm.change_state(player.fsm.states.idle)
		player.set_physics_process(false)

	# === STEP 3: STANDALONE QTE (NO ANIMATION DEPENDENCY) ===
	print("Cutscene3: Triggering Standalone QTE...")
	
	# 1. Slow Motion immediately
	Engine.time_scale = 0.05
	
	# 2. Start QTE Logic
	_start_qte_sequence()
	
	# 3. Wait for Input
	await qte_sequence_complete
	
	# 4. Cleanup
	_stop_qte_sequence()
	
	# 5. Restore Speed
	print("Cutscene3: Restoring normal time scale")
	Engine.time_scale = 1.0
	
	# 6. Handle Fail
	if qte_failed:
		await _handle_qte_failure()
		return
	
	print("Cutscene3: QTE Success")
	
	# === STEP 4: HIỂN THỊ ICON NGUYÊN TỐ HỎA ===
	await _show_element_icons()
	if animated_bg:
		(animated_bg.get_child(0) as AnimatedSprite2D).animation = "cutscene3"
		await get_tree().create_timer(0.5).timeout
		Dialogic.start("boss_phoenix")
	
	# === STEP 2: TRIGGER PARALLEL ACTIONS (NO AWAIT HERE) ===
	print("Cutscene3: Starting parallel movement and animation...")
	
	# Start movement (fire and forget)
	_move_characters_to_positions() 
	
	# Start animation immediately
	if animated_bg:
		print("Cutscene3: Playing AnimatedBg cutscene3...")
		animated_bg.play("cutscene3")
	
	Dialogic.start("boss_phoenix_after")
	await Dialogic.timeline_ended
	
	# === STEP 5: WAIT FOR ANIMATION TO FINISH ===
	if animated_bg and animated_bg.is_playing():
		await animated_bg.animation_finished
		print("Cutscene3: AnimatedBg cutscene3 finished")
	
	# === STEP 6: FLASH EFFECT ===
	await _play_flash_effect()
	
	# === STEP 7: LAND PLAYER ===
	await _land_player_on_ground()
	
	# Đợi một chút
	await get_tree().create_timer(1.0).timeout
	
	# === CRITICAL FIX: RESTORE COMBAT STATE ===
	# Unlock boss
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
	
	# Transition to standup (combat state)
	if is_instance_valid(fsm) and fsm.states.has("standup"):
		print("Cutscene3: Finished successfully, transitioning to standup")
		fsm.change_state(fsm.states.standup)
	else:
		print("ERROR: Cannot transition to standup!")

# ============= QTE FUNCTIONS =============

func _start_qte_sequence() -> void:
	qte_active = true
	qte_results.clear()
	qte_timers.clear()
	qte_failed = false
	
	print("Cutscene3: QTE sequence started with ", qte_keys.size(), " keys")
	
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
	print("Cutscene3: QTE sequence stopped")

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
	
	print("Cutscene3: Spawned QTE key #", index)

func _on_qte_key_finished(success: bool) -> void:
	qte_results.append(success)
	print("Cutscene3: QTE key ", "SUCCESS" if success else "FAILED")
	
	if not success:
		qte_failed = true
		print("Cutscene3: QTE FAILURE DETECTED")
		qte_sequence_complete.emit()
		return
	
	if qte_results.size() >= qte_keys.size():
		print("Cutscene3: All QTE keys completed")
		qte_sequence_complete.emit()

func _handle_qte_failure() -> void:
	print("Cutscene3: Handling QTE failure")
	Engine.time_scale = 0.0
	
	if player:
		player.visible = true
		player.set_physics_process(false)
	
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

	# === CRITICAL FIX: RESTORE COMBAT STATE ===
	obj.set_physics_process(true)
	
	# Re-enable hurtbox
	if obj.has_method("enable_hurtbox"):
		obj.enable_hurtbox()
	
	# Reset boss phase to combat (FLY)
	obj.current_phase = obj.Phase.FLY
	
	# Transition to Idle (Combat)
	if is_instance_valid(fsm) and fsm.states.has("standup"):
		print("Cutscene3: QTE Failed, transitioning to combat (standup)")
		fsm.change_state(fsm.states.standup)

# ============= VISUAL & MOVEMENT FUNCTIONS =============

func _show_element_icons() -> void:
	var viewport_size = obj.get_viewport_rect().size
	var center = viewport_size / 2.0
	
	var sprite = ELEMENT_SPRITE_SCENE.instantiate()
	if not sprite.set_element("fire"):
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

func _move_characters_to_positions() -> void:
	# Note: This function no longer returns 'await'. It creates tweens and lets them run.
	if not player_pos or not boss_pos:
		return
	
	# Tween Player
	if player:
		var player_tween = create_tween()
		player_tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
		player_tween.tween_property(player, "global_position", player_pos.global_position, 1.0).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
	
	# Tween Boss (Knockback effect)
	var boss_tween = obj.get_tree().create_tween()
	boss_tween.bind_node(obj)
	boss_tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	
	var knockback_direction = (boss_pos.global_position - obj.global_position).normalized()
	var overshoot_pos = boss_pos.global_position + knockback_direction * 50
	
	boss_tween.tween_property(obj, "global_position", overshoot_pos, 1.5).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	boss_tween.tween_property(obj, "global_position", boss_pos.global_position, 0.3).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

func _play_flash_effect() -> void:
	var flash = FADE_BOSS_SCENE.instantiate()
	var canvas = CanvasLayer.new()
	canvas.layer = 99
	obj.get_tree().root.add_child(canvas)
	canvas.add_child(flash)
	
	await flash.play_flash_effect(0.8)
	canvas.queue_free()

func _land_player_on_ground() -> void:
	if not player: return
	
	print("Cutscene3: Landing player...")
	player.set_physics_process(false)
	var gravity = 980.0
	
	while not player.is_on_floor():
		var delta = obj.get_physics_process_delta_time()
		player.velocity.y += gravity * delta
		player.move_and_slide()
		await obj.get_tree().physics_frame
	
	player.velocity = Vector2.ZERO
	print("Cutscene3: Player landed successfully")

func _physics_process(_delta):
	if is_instance_valid(obj):
		obj.velocity = Vector2.ZERO

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
	
	_stop_qte_sequence()
	
	if player:
		player.set_physics_process(true)
		player.visible = true
	
	# Ensure hurtbox is enabled when exiting
	if obj.has_method("enable_hurtbox"):
		obj.enable_hurtbox()
	
	print("Cutscene3: Exit")
