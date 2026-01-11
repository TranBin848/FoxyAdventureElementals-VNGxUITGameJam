extends BlackEmperorState

## ENDING A: "CÓ" (Yes - True Ending)
## Flow:
## 1. Wood magic healing animation
## 2. Fade to black -> Dialogue
## 3. Merge Sequence ("To be continued")
## 4. Credits
## 5. End Game

# References
const ELEMENT_SPRITE_SCENE = preload("res://scenes/enemies/final_boss/element_sprite.tscn")
@onready var cutscene_text_ui: Node = $GUI/CutsceneUI 
var animated_bg: AnimationPlayer = null
var player: Player = null
var player_pos: Node2D = null
var boss_pos: Node2D = null
var boss_camera: Camera2D = null
var boss_zone_camera: Camera2D = null

# Visual Effects Layers
var fade_overlay: ColorRect = null
var canvas_layer_fade: CanvasLayer = null
var flash_overlay: ColorRect = null
var canvas_layer_flash: CanvasLayer = null

# Tween management
var active_tweens: Array[Tween] = []

# Story texts for ending A
const ENDING_TEXTS = [
	"Ah… Cuối cùng thì ngươi cũng nhớ ra vài điều quan trọng mà mình đã quên mất. Một thời gian về trước, một người quan trọng đối với ngươi đã không còn nữa...",
	"Vào giờ khắc cuối cùng trước khi trở nên điên loạn hoàn toàn, một phần linh hồn của ngươi đã tách ra...",
	"Giờ đây, sau một cuộc hành trình dài, ngươi cuối cùng đã gặp lại phần linh hồn kia...",
	"Thế nhưng giờ đây, cả ngươi và nó vẫn chưa thể nhớ ra người quan trọng mà các ngươi đã đánh mất là ai..."
]

func _enter() -> void:
	print("=== State: Ending A (True Ending) Enter ===")
	
	# Kill only our tweens
	_kill_active_tweens()

	# Setup boss
	obj.change_animation("idle")
	obj.velocity = Vector2.ZERO
	obj.is_stunned = true
	obj.is_movable = false
	obj.set_physics_process(false)
	
	_find_references()
	_setup_fade_overlay()
	
	# Disable player input and movement
	if player:
		if player.fsm and player.fsm.states.has("idle"):
			player.fsm.change_state(player.fsm.states.idle)
		player.set_physics_process(false)
		player.velocity = Vector2.ZERO
		
	# Find Position Nodes
	var pos_container = obj.get_tree().root.find_child("PosBossPlayer", true, false)
	if pos_container:
		boss_pos = pos_container.get_node_or_null("BossPosCutscene6")
		player_pos = pos_container.get_node_or_null("PLayerPosCutscene6")
	else:
		push_warning("PosBossPlayer container not found - using current positions")
	
	# Switch to boss zone camera immediately for wide view
	if boss_zone_camera:
		print("Switching to boss zone camera")
		CameraTransition.transition_camera2D(boss_zone_camera, 1.5)
	else:
		push_warning("Boss zone camera not found")
	
	# Small delay to let camera transition start
	await get_tree().create_timer(0.3).timeout
	
	_start_ending_sequence()

func _find_references() -> void:
	if animated_bg == null:
		animated_bg = obj.get_tree().get_first_node_in_group("animated_bg")
	if player == null:
		player = obj.get_tree().root.find_child("Player", true, false) as Player
	if boss_camera == null:
		boss_camera = obj.get_node_or_null("Camera2D")
	if boss_zone_camera == null and obj.boss_zone:
		boss_zone_camera = obj.boss_zone.camera_2d
	if cutscene_text_ui == null:
		cutscene_text_ui = obj.get_tree().root.find_child("CutsceneUI", true, false)

func _setup_fade_overlay() -> void:
	fade_overlay = ColorRect.new()
	fade_overlay.color = Color.BLACK
	fade_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	fade_overlay.modulate.a = 0.0
	fade_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	
	canvas_layer_fade = CanvasLayer.new()
	canvas_layer_fade.layer = 50 
	obj.get_tree().root.add_child(canvas_layer_fade)
	canvas_layer_fade.add_child(fade_overlay)

func _start_ending_sequence() -> void:
	print("=== ENDING A SEQUENCE START ===")
	
	# 1. Wood Icon
	print("Step 1: Wood Icon")
	await _show_element_icons()
	await get_tree().create_timer(0.3).timeout
	
	# 2. Healing Animation
	print("Step 2: Healing Animation")
	await _play_healing_animation()
	await get_tree().create_timer(0.3).timeout
	
	# 3. Fade to Black
	print("Step 3: Fade to Black")
	await _fade_to_black(2.0)
	await get_tree().create_timer(0.5).timeout
	
	# 4. Dialogue (Happens over black screen)
	print("Step 4: Dialogue")
	await _show_ending_dialogue()
	await get_tree().create_timer(0.5).timeout
	
	# 5. MERGE SEQUENCE (Includes "To be continued")
	print("Step 5: Merge Sequence")
	await _show_merge_sequence()
	
	# 7. End Game
	print("Step 7: End Game")
	_end_game()

# ==============================================================================
#  SEQUENCE STEPS
# ==============================================================================

func _show_merge_sequence() -> void:
	print("Ending A: Starting Merge Sequence")
	
	# Ensure boss zone camera is active for wide view
	if boss_zone_camera and boss_zone_camera.enabled == false:
		CameraTransition.transition_camera2D(boss_zone_camera, 0.5)
		await get_tree().create_timer(0.5).timeout
	
	# 1. SETUP POSITIONS
	if boss_pos and player_pos:
		obj.global_position = boss_pos.global_position
		if player:
			player.global_position = player_pos.global_position
			player.visible = true 
	elif player:
		# Fallback: use current positions
		player.visible = true
	
	obj.visible = true
	obj.modulate.a = 1.0
	if player:
		player.modulate.a = 1.0
	
	# 2. FADE IN (Reveal characters standing apart)
	print("Merge: Fade in from black")
	await _fade_from_black(1.5)
	await get_tree().create_timer(1.0).timeout 
	
	# 3. CALCULATE MIDPOINT & TWEEN
	if player:
		print("Merge: Moving to midpoint")
		var mid_point = (obj.global_position + player.global_position) / 2.0
		
		var merge_duration = 2.5
		var tween = _create_managed_tween()
		tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
		tween.set_parallel(true)
		
		# Move Boss & Fade Out
		tween.tween_property(obj, "global_position", mid_point, merge_duration)\
			.set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_IN)
		tween.tween_property(obj, "modulate:a", 0.0, merge_duration)\
			.set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_IN)
		
		# Move Player & Keep Visible
		tween.tween_property(player, "global_position", mid_point, merge_duration)\
			.set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_IN)
		tween.tween_property(player, "modulate:a", 1.0, merge_duration)\
			.set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_IN)
			
		await tween.finished
		_remove_tween(tween)
		
		# Boss is now invisible at midpoint, Player is visible at midpoint
		obj.visible = false
	
	await get_tree().create_timer(0.3).timeout
	
	# 4. WHITE FLASH (Boss disappears completely, Player remains)
	print("Merge: White flash")
	await _play_white_flash()
	
	await get_tree().create_timer(0.5).timeout
	
	# 5. "To be continued..." over the scene
	print("Merge: 'To be continued' text")
	if animated_bg:
		animated_bg.play("after_credits") 
	
	if cutscene_text_ui:
		if cutscene_text_ui.has_method("show_text"):
			cutscene_text_ui.show_text("[center]To be continued...[/center]")
			AudioManager.play_music("music_credits_noncopyrighted")
			await get_tree().create_timer(1.0).timeout
		else:
			await get_tree().create_timer(3.0).timeout
	else:
		await get_tree().create_timer(3.0).timeout
	
	# Show Credits Text (smooth transition from "To be continued")
	print("Credits: Displaying credits text")
	if cutscene_text_ui and cutscene_text_ui.has_method("show_text"):
		cutscene_text_ui.show_text("[center]=== CREDITS ===\n\nGame by: Group 5\n\nThank you for playing![/center]")
		
		if cutscene_text_ui.has_signal("text_finished"):
			await cutscene_text_ui.text_finished
		else:
			await get_tree().create_timer(5.0).timeout
		
		await get_tree().create_timer(3.0).timeout
	else:
		await get_tree().create_timer(5.0).timeout
	
	# Hide Credits Text
	print("Credits: Hiding credits text")
	_hide_cutscene_text()

# ==============================================================================
#  HELPERS (Flash, Fade, etc)
# ==============================================================================

func _play_white_flash() -> void:
	"""White flash effect without hiding anything - boss is already invisible"""
	# Create flash overlay
	canvas_layer_flash = CanvasLayer.new()
	canvas_layer_flash.layer = 100 
	obj.get_tree().root.add_child(canvas_layer_flash)
	
	flash_overlay = ColorRect.new()
	flash_overlay.color = Color.WHITE
	flash_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	flash_overlay.modulate.a = 0.0 
	canvas_layer_flash.add_child(flash_overlay)
	
	# Flash in quickly
	var flash_in = _create_managed_tween()
	flash_in.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	flash_in.tween_property(flash_overlay, "modulate:a", 1.0, 0.15)
	await flash_in.finished
	_remove_tween(flash_in)
	
	await get_tree().create_timer(0.1).timeout
	
	# Flash out slowly (reveals player standing alone)
	var flash_out = _create_managed_tween()
	flash_out.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	flash_out.tween_property(flash_overlay, "modulate:a", 0.0, 2.0)
	await flash_out.finished
	_remove_tween(flash_out)
	
	# Cleanup
	if canvas_layer_flash:
		canvas_layer_flash.queue_free()
		canvas_layer_flash = null
		flash_overlay = null

func _show_element_icons() -> void:
	var viewport_size = obj.get_viewport_rect().size
	var center = viewport_size / 2.0
	
	var sprite = ELEMENT_SPRITE_SCENE.instantiate()
	if not sprite.set_element("wood"):
		sprite.queue_free()
		return
		
	var canvas = CanvasLayer.new()
	canvas.layer = 100
	obj.get_tree().root.add_child(canvas)
	canvas.add_child(sprite)
	sprite.position = center
	sprite.play_zoom_fade_effect(1.5)
	
	await sprite.tree_exited
	
	if is_instance_valid(canvas):
		canvas.queue_free()

func _play_healing_animation() -> void:
	if animated_bg:
		animated_bg.play("cutscene6")
		await animated_bg.animation_finished
		
		# === RESURRECTION: Replace Boss Sprite with Player Sprite ===
		print("Healing complete: Transforming boss into player")
		
		# 1. Fade out boss sprite
		if obj.animated_sprite:
			var boss_fade_out = _create_managed_tween()
			boss_fade_out.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
			boss_fade_out.tween_property(obj.animated_sprite, "modulate:a", 0.0, 1.0)
			await boss_fade_out.finished
			_remove_tween(boss_fade_out)
			obj.animated_sprite.visible = false
		
		# 2. Create a temporary player sprite on the boss
		var player_sprite = AnimatedSprite2D.new()
		
		# Copy the player's sprite frames
		if player and player.animated_sprite and player.animated_sprite.sprite_frames:
			player_sprite.sprite_frames = player.animated_sprite.sprite_frames
			player_sprite.animation = "idle"  # or whatever animation you want
			player_sprite.play()
		
		# 3. Position it at the boss's sprite location
		if obj.has_node("Direction"):
			obj.get_node("Direction").add_child(player_sprite)
			# Set flip_h AFTER adding to tree
			player_sprite.flip_h = (player.global_position.x - obj.global_position.x < 0)
		
		# 4. Fade in the new sprite
		player_sprite.modulate.a = 0.0
		var fade_tween = _create_managed_tween()
		fade_tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
		fade_tween.tween_property(player_sprite, "modulate:a", 1.0, 1.5)
		await fade_tween.finished
		_remove_tween(fade_tween)
		
		# Optional: Wait a moment to let player see the transformation
		await get_tree().create_timer(1.0).timeout
	else:
		await get_tree().create_timer(2.0).timeout

func _fade_to_black(duration: float) -> void:
	if fade_overlay:
		var fade_tween = _create_managed_tween()
		fade_tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
		fade_tween.tween_property(fade_overlay, "modulate:a", 1.0, duration)
		await fade_tween.finished
		_remove_tween(fade_tween)
	else:
		await get_tree().create_timer(duration).timeout

func _fade_from_black(duration: float) -> void:
	if fade_overlay:
		var fade_tween = _create_managed_tween()
		fade_tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
		fade_tween.tween_property(fade_overlay, "modulate:a", 0.0, duration)
		await fade_tween.finished
		_remove_tween(fade_tween)
	else:
		await get_tree().create_timer(duration).timeout

func _show_ending_dialogue() -> void:
	if not cutscene_text_ui:
		await get_tree().create_timer(2.0).timeout
		return
		
	cutscene_text_ui.visible = true
	
	for i in range(ENDING_TEXTS.size()):
		print("Dialogue: Showing text %d/%d" % [i + 1, ENDING_TEXTS.size()])
		
		if cutscene_text_ui.has_method("show_text"):
			cutscene_text_ui.show_text(ENDING_TEXTS[i])
			
			if cutscene_text_ui.has_signal("text_finished"):
				await cutscene_text_ui.text_finished
			else:
				await get_tree().create_timer(4.0).timeout
		else:
			await get_tree().create_timer(4.0).timeout
			
		await get_tree().create_timer(0.5).timeout
	
	# Hide dialogue UI before proceeding
	_hide_cutscene_text()
	await get_tree().create_timer(0.3).timeout

func _end_game() -> void:
	_exit()
	get_tree().change_scene_to_file("res://levels/menu/menu.tscn")

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

# ==============================================================================
#  TEXT MANAGEMENT
# ==============================================================================

func _hide_cutscene_text() -> void:
	"""Properly hides the cutscene text UI"""
	if not cutscene_text_ui:
		return
	
	# Clear the label text
	if cutscene_text_ui.has_node("DialogText"):
		var label = cutscene_text_ui.get_node("DialogText")
		if label is RichTextLabel:
			label.text = ""
	
	# Hide continue indicator
	if cutscene_text_ui.has_node("ContinueIndicator"):
		var indicator = cutscene_text_ui.get_node("ContinueIndicator")
		indicator.visible = false
	
	# Hide the entire UI
	cutscene_text_ui.visible = false

# ==============================================================================
#  STATE EXIT
# ==============================================================================

func _exit() -> void:
	print("=== State: Ending A Exit ===")
	
	# Kill our managed tweens
	_kill_active_tweens()
	
	# Cleanup overlays
	if canvas_layer_fade:
		canvas_layer_fade.queue_free()
		canvas_layer_fade = null
		fade_overlay = null
		
	if canvas_layer_flash:
		canvas_layer_flash.queue_free()
		canvas_layer_flash = null
		flash_overlay = null
	
	# Re-enable boss (if still in scene)
	if is_instance_valid(obj):
		obj.is_stunned = false
		obj.is_movable = true
		obj.set_physics_process(true)
		
		# Disable boss camera if it was enabled
		if boss_camera and is_instance_valid(boss_camera):
			boss_camera.enabled = false
	
	# Re-enable player
	if is_instance_valid(player):
		player.set_physics_process(true)
