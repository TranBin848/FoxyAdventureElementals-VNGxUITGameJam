extends BlackEmperorState

## Cutscene 3: Hiển thị icon hệ Hỏa, chạy animation cutscene3
## Flow:
## 1. Player và boss đứng yên tại vị trí hiện tại
## 2. Hiển thị icon nguyên tố Hỏa (Fire) phóng to + fade
## 3. Play animation cutscene3 trong AnimatedBg
## 4. Chuyển sang cutscene4

# Scene
const ELEMENT_SPRITE_SCENE = preload("res://scenes/enemies/final_boss/element_sprite.tscn")
const FADE_BOSS_SCENE = preload("res://scenes/enemies/final_boss/fade_boss_scene.tscn")

var animated_bg: AnimationPlayer = null
var player: Player = null
var player_pos: Node2D = null
var boss_pos: Node2D = null

func _enter() -> void:
	print("=== State: Cutscene3 Enter ===")
	
	obj.change_animation("idle")
	
	# Setup boss
	obj.velocity = Vector2.ZERO
	obj.change_animation("inactive")
	obj.is_stunned = true
	obj.is_movable = false
	obj.set_physics_process(false)
	
	# Tìm AnimatedBg
	if animated_bg == null:
		animated_bg = obj.get_tree().get_first_node_in_group("animated_bg")
	
	# Tìm player
	if player == null:
		player = obj.get_tree().root.find_child("Player", true, false) as Player
	
	# Tìm position nodes
	var pos_container = obj.get_tree().root.find_child("PosBossPlayer", true, false)
	if pos_container:
		boss_pos = pos_container.get_node_or_null("BossPosCutscene3")
		player_pos = pos_container.get_node_or_null("PLayerPosCutscene3")
		
		if player_pos:
			print("Cutscene3: Found PlayerPosCutscene3 at ", player_pos.global_position)
		if boss_pos:
			print("Cutscene3: Found BossPosCutscene3 at ", boss_pos.global_position)
		if not player_pos or not boss_pos:
			print("Warning: Position nodes not found in PosBossPlayer")
	else:
		print("Warning: PosBossPlayer container not found")
	
	# Disable player input
	if player and player.fsm:
		if player.fsm.states.has("idle"):
			player.fsm.change_state(player.fsm.states.idle)
		player.set_physics_process(false)
	
	# Bắt đầu sequence
	_start_cutscene_sequence()

func _start_cutscene_sequence() -> void:
	# === STEP 1: HIỂN THỊ ICON NGUYÊN TỐ HỎA PHÓNG TO + FADE ===
	await _show_element_icons()
	
	# === STEP 2: PLAY ANIMATION CUTSCENE3 VÀ TWEEN NHÂN VẬT ĐỒNG THỜI ===
	
	# Bắt đầu di chuyển nhân vật ngay (chạy song song, không await ngay)
	_move_characters_to_positions()
	
	# Đồng thời bắt đầu animation và đợi nó hoàn thành
	if animated_bg:
		print("Cutscene3: Playing AnimatedBg cutscene3")
		animated_bg.play("cutscene3")
		await animated_bg.animation_finished
		print("Cutscene3: AnimatedBg cutscene3 finished")
	
	# === STEP 3: FLASH EFFECT (ÁNH SÁNG LÓE) ===
	await _play_flash_effect()
	
	# Đợi một chút trước khi chuyển sang cutscene4
	await get_tree().create_timer(2.0).timeout
	
	obj.set_physics_process(true)
	# Kiểm tra obj vẫn còn valid
	
	if is_instance_valid(fsm) and fsm.states.has("cutscene4"):
		print("Cutscene3: Finished, transitioning to Cutscene4")
		fsm.change_state(fsm.states.cutscene4)
	else:
		print("ERROR: Cannot transition to cutscene4!")

func _show_element_icons() -> void:
	"""Hiển thị icon nguyên tố Hỏa (Fire) phóng to lên toàn màn hình rồi mờ dần"""
	
	# Lấy viewport center để spawn icon ở giữa màn hình
	var viewport_size = obj.get_viewport_rect().size
	var center = viewport_size / 2.0
	
	# Cutscene3: Hiển thị hệ Hỏa (Fire)
	var sprite = ELEMENT_SPRITE_SCENE.instantiate()
	
	# Set element và load texture
	if not sprite.set_element("fire"):
		print("Warning: Failed to load fire element icon")
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
	
	print("Cutscene3: Fire element icon shown")

func _move_characters_to_positions() -> void:
	"""Player và boss bay tới vị trí mới đồng thời"""
	
	if not player_pos or not boss_pos:
		print("Warning: Position nodes not found!")
		await get_tree().create_timer(0.5).timeout
		return
	
	print("Cutscene3: Moving player and boss to new positions")
	
	# Tạo tween cho player
	var player_tween: Tween = null
	if player:
		player_tween = create_tween()
		player_tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
		player_tween.tween_property(player, "global_position", player_pos.global_position, 1.0).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
	
	# Tạo tween cho boss với hiệu ứng bị đánh bật
	# Boss sẽ bay nhanh ra xa một chút rồi về vị trí đích (knockback effect)
	var boss_tween = obj.get_tree().create_tween()
	boss_tween.bind_node(obj)
	boss_tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	
	# Tính hướng bị đánh bật (từ vị trí hiện tại đến target)
	var knockback_direction = (boss_pos.global_position - obj.global_position).normalized()
	var overshoot_pos = boss_pos.global_position + knockback_direction * 50  # Bay xa hơn 50 pixels
	
	# Bay nhanh đến vị trí overshoot (0.4s), sau đó về vị trí đích (0.5s)
	boss_tween.tween_property(obj, "global_position", overshoot_pos, 1.5).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	boss_tween.tween_property(obj, "global_position", boss_pos.global_position, 0.3).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	
	# Đợi cả 2 tweens hoàn thành
	if player_tween:
		await player_tween.finished
	if boss_tween:
		await boss_tween.finished
	
	print("Cutscene3: Characters arrived at new positions")

func _play_flash_effect() -> void:
	"""Tạo hiệu ứng ánh sáng lóe lên"""
	# Spawn flash effect trong CanvasLayer
	var flash = FADE_BOSS_SCENE.instantiate()
	
	var canvas_layer = CanvasLayer.new()
	canvas_layer.layer = 99  # Layer 99 để hiển thị dưới element sprite (layer 100)
	obj.get_tree().root.add_child(canvas_layer)
	canvas_layer.add_child(flash)
	
	# Play flash effect và đợi nó hoàn thành
	await flash.play_flash_effect(0.8)
	
	# Xóa canvas layer
	canvas_layer.queue_free()
	
	print("Cutscene3: Flash effect completed")

func _physics_process(_delta):
	# Giữ boss đứng yên
	obj.velocity = Vector2.ZERO

func _exit() -> void:
	obj.is_stunned = false
	obj.is_movable = true
	obj.set_physics_process(true)
	
	# Re-enable player input
	if player:
		player.set_physics_process(true)
	
	print("Cutscene3: Exit")
