extends BlackEmperorState

## Cutscene 3: Hiển thị icon hệ Hỏa, chạy animation cutscene3 + QTE
## Flow:
## 1. Hiển thị icon nguyên tố Hỏa (Fire) phóng to + fade
## 2. Play animation -> Wait for Signal -> Slow Motion -> QTE (Key E) -> Resume
## 3. Flash effect
## 4. Chuyển sang cutscene4

# Scene
const ELEMENT_SPRITE_SCENE = preload("res://scenes/enemies/final_boss/element_sprite.tscn")
const FADE_BOSS_SCENE = preload("res://scenes/enemies/final_boss/fade_boss_scene.tscn")
const QTE_PATH = "res://scenes/ui/popup/quick_time_event.tscn"

# ✅ SIGNAL to break the await immediately when QTE is done
signal qte_sequence_complete

var animated_bg: AnimationPlayer = null
var player: Player = null
var player_pos: Node2D = null
var boss_pos: Node2D = null
var canvas_layer: CanvasLayer = null
@onready var ui: CanvasLayer = $"../../UI"

# QTE Variables
var qte_container: Control = null
# Config for Fire Element QTE (Usually aggressive, let's use 'E')
var qte_keys = [
	{"keyString": "E", "keyCode": KEY_E, "delay": 0.0, "eventDuration": 2.0, "displayDuration": 1.0}
]
var qte_results: Array = []
var qte_active: bool = false
var qte_timers: Array = []
var qte_failed: bool = false

func _enter() -> void:
	print("=== State: Cutscene3 Enter ===")
	
	obj.change_animation("idle")
	
	# Kill tweens
	var all_tweens = obj.get_tree().get_processed_tweens()
	for t in all_tweens:
		if t.is_valid(): t.kill()
	
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
	
	# Tìm position nodes
	var pos_container = obj.get_tree().root.find_child("PosBossPlayer", true, false)
	if pos_container:
		boss_pos = pos_container.get_node_or_null("BossPosCutscene3")
		player_pos = pos_container.get_node_or_null("PLayerPosCutscene3")
	else:
		print("Warning: PosBossPlayer container not found")
	
	# Disable player input
	if player and player.fsm:
		if player.fsm.states.has("idle"):
			player.fsm.change_state(player.fsm.states.idle)
		player.set_physics_process(false)
	
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
	# === STEP 1: HIỂN THỊ ICON NGUYÊN TỐ HỎA ===
	await _show_element_icons()
	
	# === STEP 2: PLAY ANIMATION + QTE + MOVEMENT ===
	
	# Bắt đầu di chuyển nhân vật ngay (chạy song song)
	_move_characters_to_positions()
	
	if animated_bg:
		print("Cutscene3: Triggering AnimatedBg...")
		
		# 1. Start animation
		animated_bg.play("cutscene3")
		
		# 2. ✅ WAIT FOR SIGNAL
		print("Cutscene3: Waiting for animation trigger...")
		await animated_bg.qte_trigger_moment
		
		# 3. Slow Motion
		print("Cutscene3: Trigger received! Slowing down...")
		Engine.time_scale = 0.05
		
		# 4. Start QTE
		_start_qte_sequence()
		
		# 5. Wait for input
		await qte_sequence_complete
		
		# 6. Cleanup
		_stop_qte_sequence()
		
		# 7. Restore Speed
		print("Cutscene3: Restoring normal time scale")
		Engine.time_scale = 1.0
		
		# 8. Handle Fail
		if qte_failed:
			animated_bg.pause()
			await _handle_qte_failure()
			return
			
		# 9. Success Logic
		print("Cutscene3: QTE Success")
		if animated_bg.is_playing():
			await animated_bg.animation_finished
			print("Cutscene3: AnimatedBg cutscene3 finished")
	
	# === STEP 3: FLASH EFFECT ===
	await _play_flash_effect()
	
	# Đợi một chút
	await get_tree().create_timer(2.0).timeout
	
	# Unlock and Transition
	obj.set_physics_process(true)
	
	if is_instance_valid(fsm) and fsm.states.has("cutscene4"):
		print("Cutscene3: Finished, transitioning to Cutscene4")
		fsm.change_state(fsm.states.cutscene4)
	else:
		print("ERROR: Cannot transition to cutscene4!")

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
	
	await get_tree().create_timer(1.0, true, false, true).timeout 
	
	Engine.time_scale = 1.0
	if animated_bg: animated_bg.speed_scale = 1.0
	
	if canvas_layer: canvas_layer.visible = true
	if ui: ui.visible = true
	
	if GameManager and GameManager.player:
		player.take_damage(99999)

	obj.set_physics_process(true)
	
	if is_instance_valid(fsm) and fsm.states.has("idle"):
		fsm.change_state(fsm.states.idle)

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
	if not player_pos or not boss_pos:
		return
	
	# Tween Player
	var player_tween: Tween = null
	if player:
		player_tween = create_tween()
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
	
	if player_tween: await player_tween.finished
	if boss_tween: await boss_tween.finished

func _play_flash_effect() -> void:
	var flash = FADE_BOSS_SCENE.instantiate()
	var canvas = CanvasLayer.new()
	canvas.layer = 99
	obj.get_tree().root.add_child(canvas)
	canvas.add_child(flash)
	
	await flash.play_flash_effect(0.8)
	canvas.queue_free()

func _physics_process(_delta):
	if is_instance_valid(obj):
		obj.velocity = Vector2.ZERO

func _exit() -> void:
	obj.is_stunned = false
	obj.is_movable = true
	obj.set_physics_process(true)
	
	_stop_qte_sequence()
	if qte_container and qte_container.get_parent():
		qte_container.get_parent().queue_free()
	
	if player:
		player.set_physics_process(true)
		player.visible = true
	
	print("Cutscene3: Exit")
