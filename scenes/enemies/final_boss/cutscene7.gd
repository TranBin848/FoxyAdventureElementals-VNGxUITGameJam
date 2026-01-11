extends BlackEmperorState

## ENDING B: "KHÔNG" (No - Time Loop Ending)
## Flow:
## 1. Dialogue with Foxy (via Dialogic)
## 2. Boss body glows (visual effect)
## 3. Boss final words (via Dialogic)
## 4. Time magic activation
## 5. Clock/time reversal video
## 6. Loop back to beginning

# References
const VIDEO_PATH = "res://assets/cutscene/Clock.ogv" 
const SOUND_PATH = "res://assets/sounds/clock_sound.wav"
const TARGET_SCENE = "res://levels/level_0/level_0.tscn"

var animated_bg: AnimationPlayer = null
var player: Player = null
var boss_camera: Camera2D = null
var boss_zone_camera: Camera2D = null

# Visual Effects
var glow_overlay: ColorRect = null
var canvas_layer_glow: CanvasLayer = null

# Video playback
var canvas_layer_video: CanvasLayer = null
var video_player: VideoStreamPlayer = null
var audio_player: AudioStreamPlayer = null

# Tween management
var active_tweens: Array[Tween] = []

func _enter() -> void:
	print("=== State: Ending B (Time Loop) Enter ===")
	
	# Kill active tweens
	_kill_active_tweens()
	
	# Setup boss
	obj.change_animation("idle")
	obj.velocity = Vector2.ZERO
	obj.is_stunned = true
	obj.is_movable = false
	obj.set_physics_process(false)
	
	_find_references()
	_setup_glow_overlay()
	
	# Disable player input
	if player:
		if player.fsm and player.fsm.states.has("idle"):
			player.fsm.change_state(player.fsm.states.idle)
		player.set_physics_process(false)
		player.velocity = Vector2.ZERO
	
	# Switch to boss zone camera for wide view
	if boss_zone_camera:
		print("Switching to boss zone camera")
		CameraTransition.transition_camera2D(boss_zone_camera, 1.5)
	else:
		push_warning("Boss zone camera not found")
	
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

func _setup_glow_overlay() -> void:
	"""Creates a white overlay for the glow effect"""
	glow_overlay = ColorRect.new()
	glow_overlay.color = Color.WHITE
	glow_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	glow_overlay.modulate.a = 0.0
	glow_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	
	canvas_layer_glow = CanvasLayer.new()
	canvas_layer_glow.layer = 50 
	obj.get_tree().root.add_child(canvas_layer_glow)
	canvas_layer_glow.add_child(glow_overlay)

func _start_ending_sequence() -> void:
	print("=== ENDING B SEQUENCE START ===")
	
	# 2. Boss Body Begins to Glow
	print("Step 2: Boss glowing")
	await _boss_glow_effect()
	await get_tree().create_timer(0.5).timeout
	
	# 3. Boss's Final Words
	print("Step 3: Boss's declaration")
	await _show_boss_dialogue()
	await get_tree().create_timer(0.5).timeout
	
	# 4. Time Magic Activation (intensify glow)
	print("Step 4: Time magic activation")
	await _time_magic_activation()
	await get_tree().create_timer(0.3).timeout
	
	# 5. Clock Video (Time Reversal)
	print("Step 5: Time reversal video")
	await _play_clock_video()
	
	# 6. Reset Game (handled in _on_video_finished)

# ==============================================================================
#  SEQUENCE STEPS
# ==============================================================================
func _boss_glow_effect() -> void:
	"""Boss body begins to glow with pulsing effect"""
	print("Boss: Starting glow effect")
	
	# Ensure boss is visible
	obj.visible = true
	
	# Apply shader or modulate for glow
	if obj.animated_sprite:
		# Pulse the brightness
		var pulse_tween = _create_managed_tween()
		pulse_tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
		pulse_tween.set_loops(3) # Pulse 3 times
		
		pulse_tween.tween_property(obj.animated_sprite, "modulate", Color(2.0, 2.0, 2.0, 1.0), 0.5)
		pulse_tween.tween_property(obj.animated_sprite, "modulate", Color(1.0, 1.0, 1.0, 1.0), 0.5)
		
		await pulse_tween.finished
		_remove_tween(pulse_tween)
	else:
		await get_tree().create_timer(3.0).timeout

func _show_boss_dialogue() -> void:
	"""Shows Boss's final declaration"""
	Dialogic.start("bad_ending")
	await Dialogic.timeline_ended
	
func _time_magic_activation() -> void:
	"""Fade to black as time magic activates"""
	print("Time magic: Activating - Fading to black")
	
	# Change overlay to black and fade to black
	if glow_overlay:
		glow_overlay.color = Color.BLACK
		glow_overlay.modulate.a = 0.0
		
		var black_tween = _create_managed_tween()
		black_tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
		black_tween.tween_property(glow_overlay, "modulate:a", 1.0, 2.0)
		
		await black_tween.finished
		_remove_tween(black_tween)
	else:
		await get_tree().create_timer(2.0).timeout

func _play_clock_video() -> void:
	"""Plays the clock time reversal video"""
	print("🎬 Playing Clock Video")
	
	# 1. Setup CanvasLayer for Video
	canvas_layer_video = CanvasLayer.new()
	canvas_layer_video.layer = 128 # On top of everything
	obj.get_tree().root.add_child(canvas_layer_video)
	
	# 2. Black Background
	var color_rect = ColorRect.new()
	color_rect.color = Color.BLACK
	color_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	canvas_layer_video.add_child(color_rect)
	
	# 3. Setup Audio
	audio_player = AudioStreamPlayer.new()
	AudioManager.stop_ambience()
	AudioManager.stop_music()
	
	var sound_stream = load(SOUND_PATH)
	if sound_stream:
		audio_player.stream = sound_stream
		audio_player.bus = "Master"
	canvas_layer_video.add_child(audio_player)
	
	# 4. Setup Video
	video_player = VideoStreamPlayer.new()
	var video_stream = load(VIDEO_PATH)
	if video_stream:
		video_player.stream = video_stream
	
	video_player.set_anchors_preset(Control.PRESET_FULL_RECT)
	video_player.expand = true
	video_player.loop = false
	video_player.z_index = 1
	
	video_player.finished.connect(_on_video_finished)
	color_rect.add_child(video_player)
	
	# 5. Start Playback
	if video_stream: video_player.play()
	if sound_stream: audio_player.play()
	
	# 6. Background Load Target Scene
	print("⏳ Background loading Level 0...")
	ResourceLoader.load_threaded_request(TARGET_SCENE)

func _on_video_finished() -> void:
	print("🎬 Clock Video Finished. Time Loop Reset...")
	
	if video_player: video_player.stop()
	if audio_player: audio_player.stop()
	
	# Ensure load is complete
	var status = ResourceLoader.load_threaded_get_status(TARGET_SCENE)
	while status == ResourceLoader.THREAD_LOAD_IN_PROGRESS:
		await get_tree().create_timer(0.1).timeout
		status = ResourceLoader.load_threaded_get_status(TARGET_SCENE)
	
	_exit()
	GameManager.clear_checkpoint_data()
	get_tree().change_scene_to_file(TARGET_SCENE)

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
#  STATE EXIT
# ==============================================================================

func _exit() -> void:
	print("=== State: Ending B Exit ===")
	
	# Kill managed tweens
	_kill_active_tweens()
	
	# Cleanup glow overlay
	if canvas_layer_glow:
		canvas_layer_glow.queue_free()
		canvas_layer_glow = null
		glow_overlay = null
	
	# Cleanup video layer
	if canvas_layer_video:
		canvas_layer_video.queue_free()
		canvas_layer_video = null
	
	if audio_player:
		audio_player.stop()
		audio_player.queue_free()
		audio_player = null
	
	# Re-enable boss (if still in scene)
	if is_instance_valid(obj):
		obj.is_stunned = false
		obj.is_movable = true
		obj.set_physics_process(true)
		
		if boss_camera and is_instance_valid(boss_camera):
			boss_camera.enabled = false
	
	# Re-enable player
	if is_instance_valid(player):
		player.set_physics_process(true)
