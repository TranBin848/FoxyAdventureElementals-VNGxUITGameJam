extends BlackEmperorState

## Cutscene 5: Simultaneous Move -> QTE -> Metal Icon -> Animation -> Dialog -> Branching Transition
## Flow:
## 1. Setup & Disable Input
## 2. SIMULTANEOUS: Boss Move + Player Move + Camera Zoom Out
## 3. STANDALONE QTE (Key F) -> Slow Motion -> Success/Fail
## 4. Element Icon (Metal)
## 5. Play Animation "cutscene5"
## 6. Dialogic Decision
## 7. Transition to Cutscene 6 (Default) or 7 (Alternative)

# Scene
const ELEMENT_SPRITE_SCENE = preload("res://scenes/enemies/final_boss/element_sprite.tscn")
const QTE_PATH = "res://scenes/ui/popup/quick_time_event.tscn"
const DIALOG_TIMELINE = "endgame_choice" # Ensure this matches your Dialogic Timeline name

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
# Config for Metal Element QTE (Key F)
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
	print("=== State: Cutscene5 Enter ===")
	
	obj.change_animation("idle")
	
	# Kill only our managed tweens (not CameraTransition's!)
	_kill_active_tweens()
	
	# Setup boss
	obj.velocity = Vector2.ZERO
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
		boss_pos = pos_container.get_node_or_null("BossPosCutscene5")
		player_pos = pos_container.get_node_or_null("PLayerPosCutscene5")
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
	
	# Switch to boss_zone camera immediately
	if boss_zone_camera:
		print("Cutscene5: Switching to boss_zone camera")
		CameraTransition.transition_camera2D(boss_zone_camera, 1.5)
	else:
		push_warning("Boss zone camera not found")
	
	await get_tree().create_timer(0.3).timeout
	
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
	qte_container.name = "QTE_Container_C5"
	qte_container.set_anchors_preset(Control.PRESET_FULL_RECT)
	qte_container.mouse_filter = Control.MOUSE_FILTER_IGNORE
	
	var canvas = CanvasLayer.new()
	canvas.layer = 100
	canvas.name = "QTE_CanvasLayer_C5"
	obj.get_tree().root.add_child(canvas)
	canvas.add_child(qte_container)

func _start_cutscene_sequence() -> void:
	# === STEP 1: PARALLEL MOVEMENT & CAMERA ===
	# We perform camera switch, boss move, and player move ALL AT ONCE
	await _move_characters_and_camera()
	
	Dialogic.start("metal_ultimate")
	await Dialogic.timeline_ended
	
	# === STEP 2: STANDALONE QTE ===
	print("Cutscene5: Triggering Standalone QTE...")
	
	# 1. Slow Motion
	Engine.time_scale = 0.05
	
	# 2. Start QTE Logic
	_start_qte_sequence()
	
	# 3. Wait for Input
	await qte_sequence_complete
	
	# 4. Cleanup
	_stop_qte_sequence()
	
	# 5. Restore Speed
	print("Cutscene5: Restoring normal time scale")
	Engine.time_scale = 1.0
	
	# 6. Handle Fail
	if qte_failed:
		await _handle_qte_failure()
		return

	print("Cutscene5: QTE Success")

	# === STEP 3: HIỂN THỊ ICON NGUYÊN TỐ MỘC (METAL) ===
	await _show_element_icons()
	
	# === STEP 4: PLAY ANIMATION ===
	if animated_bg:
		print("Cutscene5: Playing AnimatedBg cutscene5...")
		animated_bg.play("cutscene5")
		await animated_bg.animation_finished
		print("Cutscene5: AnimatedBg cutscene5 finished")
	
	# === STEP 5: DIALOGIC DECISION ===
	print("Cutscene5: Starting Dialog...")
	
	# Start Dialog
	var dialog = Dialogic.start(DIALOG_TIMELINE)
	add_child(dialog)
	
	# Wait for dialog to end
	if dialog.has_signal("timeline_end"):
		await dialog.timeline_end
	elif Dialogic.has_signal("timeline_ended"):
		await Dialogic.timeline_ended
		
	print("Cutscene5: Dialog finished")
	
	# === STEP 6: BRANCHING TRANSITION ===
	
	# 1. Get the decision variable from Dialogic (Must match Editor variable name)
	var player_decision = Dialogic.VAR.get_variable("boss_choice")
	print("Player decision: ", player_decision)
	
	# 2. Unlock physics
	obj.set_physics_process(true)
	
	# 3. Branch based on choice
	if player_decision == "badEnding":
		print("Transitioning to Cutscene 7 (Alternative)")
		if fsm.states.has("cutscene7"):
			fsm.change_state(fsm.states.cutscene7)
		else:
			print("ERROR: 'cutscene7' state not found!")
	else:
		print("Transitioning to Cutscene 6 (Default)")
		if fsm.states.has("cutscene6"):
			fsm.change_state(fsm.states.cutscene6)
		else:
			print("ERROR: 'cutscene6' state not found!")

# ============= MOVEMENT FUNCTIONS =============

func _move_characters_and_camera() -> void:
	print("Cutscene5: Starting simultaneous movement sequence...")
	
	# 1. Switch to Wide Camera (Boss Zone) immediately so we can see movement
	if boss_zone_camera:
		CameraTransition.transition_camera2D(boss_zone_camera, 1.5)
	
	var movement_duration = 2.0
	var tweens_finished = 0
	var total_tweens = 0
	
	# 2. Setup Boss Tween
	if boss_pos:
		total_tweens += 1
		var boss_tween = obj.get_tree().create_tween()
		boss_tween.bind_node(obj)
		boss_tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
		boss_tween.set_parallel(true)
		
		# Move Boss
		boss_tween.tween_property(obj, "global_position", boss_pos.global_position, movement_duration)\
			.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN_OUT)
		
		# Wait for completion
		boss_tween.chain().tween_callback(func(): 
			obj.global_position = boss_pos.global_position
			boss_locked_position = boss_pos.global_position
			is_boss_locked = true
		)
	
	# 3. Setup Player Tween
	if player and player_pos:
		total_tweens += 1
		var player_tween = create_tween()
		player_tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
		
		# Move Player
		player_tween.tween_property(player, "global_position", player_pos.global_position, movement_duration)\
			.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)

	# 4. Wait for movements (Approximate wait to ensure sync)
	if total_tweens > 0:
		await get_tree().create_timer(movement_duration + 0.1).timeout
		
	print("Cutscene5: Characters in position")

# ============= QTE FUNCTIONS =============

func _start_qte_sequence() -> void:
	qte_active = true
	qte_results.clear()
	qte_timers.clear()
	qte_failed = false
	
	print("Cutscene5: QTE sequence started with ", qte_keys.size(), " keys")
	
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
	print("Cutscene5: QTE sequence stopped")

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
	
	print("Cutscene5: Spawned QTE key #", index)

func _on_qte_key_finished(success: bool) -> void:
	qte_results.append(success)
	print("Cutscene5: QTE key ", "SUCCESS" if success else "FAILED")
	
	if not success:
		qte_failed = true
		print("Cutscene5: QTE FAILURE DETECTED")
		qte_sequence_complete.emit()
		return
	
	if qte_results.size() >= qte_keys.size():
		print("Cutscene5: All QTE keys completed")
		qte_sequence_complete.emit()

func _handle_qte_failure() -> void:
	print("Cutscene5: Handling QTE failure")
	Engine.time_scale = 0.0
	
	await get_tree().create_timer(1.0, true, false, true).timeout 
	
	Engine.time_scale = 1.0
	if animated_bg: animated_bg.speed_scale = 1.0
	
	if canvas_layer: canvas_layer.visible = true
	if ui: ui.visible = true
	
	# Re-enable physics processing so dead state can run
	if player:
		player.set_physics_process(true)
	
	if GameManager and GameManager.player:
		player.fsm.current_state.take_damage(Vector2.ZERO, 99999)

	obj.set_physics_process(true)
	is_boss_locked = false
	
	if is_instance_valid(fsm) and fsm.states.has("idle"):
		fsm.change_state(fsm.states.idle)

# ============= VISUAL FUNCTIONS =============

func _show_element_icons() -> void:
	"""Hiển thị icon nguyên tố Kim (Metal) phóng to lên toàn màn hình rồi mờ dần"""
	var viewport_size = obj.get_viewport_rect().size
	var center = viewport_size / 2.0
	
	var sprite = ELEMENT_SPRITE_SCENE.instantiate()
	
	if not sprite.set_element("metal"):
		print("Warning: Failed to load metal element icon")
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
	
	if boss_camera:
		boss_camera.enabled = false
	
	print("Cutscene5: Exit")
