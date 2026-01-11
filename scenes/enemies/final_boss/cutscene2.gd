extends BlackEmperorState

## Cutscene 2: Camera focus boss, boss di chuyển, zoom out, player di chuyển, play animation + QTE
## Flow:
## 1-6: Setup positions & Boss Movement
## 7: QTE Sequence (Via Animation Trigger)
## 8: Element Icons
## 9-10: Camera Zoom Out & Player Movement
## 11: Flash effect
## 12: Land player

# Scene paths
const ELEMENT_SPRITE_PATH = "res://scenes/enemies/final_boss/element_sprite.tscn"
const FADE_BOSS_PATH = "res://scenes/enemies/final_boss/fade_boss_scene.tscn"

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

# --- NEW VARIABLE FOR SYNC ---
var chant_signal_received: bool = false

# Tween management
var active_tweens: Array[Tween] = []

func _enter() -> void:
	print("=== State: Cutscene2 Enter ===")
	
	# --- CONNECT DIALOGIC SIGNAL ---
	if not Dialogic.signal_event.is_connected(_on_dialogic_signal):
		Dialogic.signal_event.connect(_on_dialogic_signal)
	chant_signal_received = false
	
	obj.change_animation("idle")
	
	await get_tree().create_timer(0.5).timeout
	
	# Kill only our managed tweens (not CameraTransition's!)
	_kill_active_tweens()
	
	# Setup boss
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
		boss_pos = pos_container.get_node_or_null("BossPosCutscene2")
		player_pos = pos_container.get_node_or_null("PLayerPosCutscene2")
	
	# Tìm player
	if player == null:
		player = GameManager.player as Player
	
	# Tìm camera boss
	if boss_camera == null:
		boss_camera = obj.get_node_or_null("Camera2D")
	
	# Tìm camera boss_zone
	if boss_zone_camera == null and obj.boss_zone:
		boss_zone_camera = obj.boss_zone.camera_2d
	
	# Switch to boss_zone camera immediately
	if boss_zone_camera:
		print("Cutscene2: Switching to boss_zone camera")
		CameraTransition.transition_camera2D(boss_zone_camera, 1.5)
	else:
		push_warning("Boss zone camera not found")
	
	await get_tree().create_timer(0.3).timeout
	
	# Bắt đầu sequence
	_start_cutscene_sequence()

# --- NEW FUNCTION TO HANDLE DIALOGIC SIGNALS ---
func _on_dialogic_signal(argument: String) -> void:
	if argument == "fire_boss_chant":
		print("Cutscene2: Received signal 'fire_boss_chant' from Dialogic")
		chant_signal_received = true

func _start_cutscene_sequence() -> void:
	# === STEP 1: DISABLE PLAYER INPUT ===
	if player and player.fsm:
		if player.fsm.states.has("idle"):
			player.fsm.change_state(player.fsm.states.idle)
		player.set_physics_process(false)
	
	# === STEP 2: BOSS DI CHUYỂN TỚI VỊ TRÍ CUTSCENE2 ===
	await _move_boss_to_position()
	
	# === STEP 3: ZOOM CAMERA RA TOÀN CẢNH ===
	await get_tree().create_timer(0.5).timeout
	
	# Start dialog
	Dialogic.start("boss_chanting")
	
	# === STEP 5: BẮT ĐẦU ANIMATION + QTE SEQUENCE (SYNCED) ===
	if animated_bg:
		print("Cutscene2: Waiting for 'fire_boss_chant' signal...")
		
		# --- PAUSE HERE UNTIL SIGNAL IS RECEIVED ---
		while not chant_signal_received:
			await obj.get_tree().process_frame
			
		print("Cutscene2: Signal received. Triggering AnimatedBg...")
		
		if player:
			player.visible = false
		
		# 1. Start animation
		await get_tree().create_timer(0.5).timeout
		animated_bg.play("cutscene2")
		
		if animated_bg.is_playing():
			await animated_bg.animation_finished
	
	# === STEP 6: PLAYER DI CHUYỂN TỚI VỊ TRÍ CUTSCENE2 ===
	await _move_player_to_position()
	
	# === STEP 7: FLASH EFFECT ===
	await _play_flash_effect()
	
	# === STEP 8: PLAYER DEAD ANIMATION & LANDING ===
	if player:
		player.visible = true
		player.change_animation("dead") # Keep existing logic from original script
	
	await _land_player_on_ground()
	
	# Đợi một chút trước khi chuyển sang cutscene3
	await get_tree().create_timer(1.5).timeout
	
	# Unlock boss và chuyển sang cutscene3
	is_boss_locked = false
	obj.set_physics_process(true)
	
	if is_instance_valid(fsm) and fsm.states.has("cutscene3"):
		print("Cutscene2: Finished, transitioning to Cutscene3")
		fsm.change_state(fsm.states.cutscene3)
	else:
		print("ERROR: Cannot transition to cutscene3!")

# ============= MOVEMENT & EFFECTS FUNCTIONS =============

func _move_boss_to_position() -> void:
	if not boss_pos: return
	
	var target_pos = boss_pos.global_position
	
	await get_tree().process_frame
	
	obj.velocity = Vector2.ZERO
	obj.change_animation("moving")
	
	var fly_tween = _create_managed_tween()
	fly_tween.bind_node(obj)
	fly_tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	fly_tween.tween_property(obj, "global_position", target_pos, 1.5).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN_OUT)
	
	await fly_tween.finished
	_remove_tween(fly_tween)
	
	obj.global_position = target_pos
	boss_locked_position = target_pos
	is_boss_locked = true
	obj.change_animation("idle")

func _move_player_to_position() -> void:
	if not player or not player_pos: return
	
	var player_tween = create_tween()
	player_tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	player_tween.tween_property(player, "global_position", player_pos.global_position, 1.2).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
	await player_tween.finished

func _land_player_on_ground() -> void:
	if not player: return
	print("Cutscene2: Landing player...")
	player.set_physics_process(false)
	var gravity = 980.0
	while not player.is_on_floor():
		var delta = obj.get_physics_process_delta_time()
		player.velocity.y += gravity * delta
		player.move_and_slide()
		await obj.get_tree().physics_frame
	player.velocity = Vector2.ZERO
	print("Cutscene2: Player landed")

func _play_flash_effect() -> void:
	var flash = load(FADE_BOSS_PATH).instantiate()
	var canvas = CanvasLayer.new()
	canvas.layer = 99
	obj.get_tree().root.add_child(canvas)
	canvas.add_child(flash)
	await flash.play_flash_effect(0.8)
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
	
	# --- CLEANUP SIGNAL ---
	if Dialogic.signal_event.is_connected(_on_dialogic_signal):
		Dialogic.signal_event.disconnect(_on_dialogic_signal)
		
	obj.is_stunned = false
	obj.is_movable = true
	obj.set_physics_process(true)
	is_boss_locked = false
	
	if player:
		player.set_physics_process(true)
		player.visible = true
	
	if boss_camera:
		boss_camera.enabled = false
	
	print("Cutscene2: Exit")
