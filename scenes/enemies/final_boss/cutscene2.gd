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

func _enter() -> void:
	print("=== State: Cutscene2 Enter ===")
	
	obj.change_animation("idle")
	
	await get_tree().create_timer(0.5).timeout
	
	# Kill tất cả tweens cũ
	var all_tweens = obj.get_tree().get_processed_tweens()
	print("Cutscene2: Killing ", all_tweens.size(), " active tweens")
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
	
	# === STEP 5: BẮT ĐẦU ANIMATION + QTE SEQUENCE ===
	if animated_bg:
		print("Cutscene2: Triggering AnimatedBg...")
		
		if player:
			player.visible = false
		
		# 1. Start animation
		animated_bg.play("cutscene2")
		
		if animated_bg.is_playing():
			await animated_bg.animation_finished
	
	# === STEP 6: PLAYER DI CHUYỂN TỚI VỊ TRÍ CUTSCENE2 ===
	await _move_player_to_position()
	
	# === STEP 7: FLASH EFFECT ===
	await _play_flash_effect()
	
	# === STEP 8: PLAYER DEAD ANIMATION & LANDING ===
	if player:
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
	var all_tweens = obj.get_tree().get_processed_tweens()
	for t in all_tweens:
		if t.is_valid(): t.kill()
	
	await get_tree().process_frame
	
	obj.velocity = Vector2.ZERO
	obj.change_animation("moving")
	
	var fly_tween = obj.get_tree().create_tween()
	fly_tween.bind_node(obj)
	fly_tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	fly_tween.tween_property(obj, "global_position", target_pos, 1.5).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN_OUT)
	
	await fly_tween.finished
	
	obj.global_position = target_pos
	boss_locked_position = target_pos
	is_boss_locked = true
	obj.change_animation("idle")

func _zoom_camera_out() -> void:
	if boss_zone_camera:
		print("Cutscene2: Switching to boss_zone camera (zoom out)")
		CameraTransition.transition_camera2D(boss_zone_camera, 1.0)
		await get_tree().create_timer(1.0).timeout

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

func _exit() -> void:
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
