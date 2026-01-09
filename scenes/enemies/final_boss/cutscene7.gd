extends BlackEmperorState

# --- CONFIGURATION ---
const VIDEO_PATH = "res://assets/cutscene/Clock.ogv" 
const SOUND_PATH = "res://assets/sounds/clock_sound.wav"
const TARGET_SCENE = "res://levels/level_0/level_0.tscn"

# We hold a reference to the CanvasLayer so we can delete it later
var canvas_layer: CanvasLayer = null
var video_player: VideoStreamPlayer = null
var audio_player: AudioStreamPlayer = null

func _enter() -> void:
	print("🎬 Cutscene 7 Started")
	
	# 1. Setup CanvasLayer (The Container)
	# This ensures the video draws ON TOP of everything (UI, Game, etc.)
	# and stays fixed to the screen.
	canvas_layer = CanvasLayer.new()
	canvas_layer.layer = 128 # High number to ensure it's on top of HUD
	add_child(canvas_layer)
	
	# 2. Setup Background (Black)
	var color_rect = ColorRect.new()
	color_rect.color = Color.BLACK
	color_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	# Add ColorRect to the CanvasLayer, not the State node
	canvas_layer.add_child(color_rect)
	
	# 3. Setup Audio
	audio_player = AudioStreamPlayer.new()
	AudioManager.stop_ambience()
	AudioManager.stop_music()
	var sound_stream = load(SOUND_PATH)
	if sound_stream:
		audio_player.stream = sound_stream
		audio_player.bus = "Master"
	add_child(audio_player) # Audio can stay on the State node, that's fine
	
	# 4. Setup Video
	video_player = VideoStreamPlayer.new()
	var video_stream = load(VIDEO_PATH)
	if video_stream:
		video_player.stream = video_stream
	
	# Configure Video
	video_player.set_anchors_preset(Control.PRESET_FULL_RECT)
	video_player.expand = true
	video_player.loop = false
	video_player.z_index = 1 # Just to be safe within the CanvasLayer
	
	# Connect signal
	video_player.finished.connect(_on_video_finished)
	
	# Add Video to the ColorRect (so it's inside the CanvasLayer)
	color_rect.add_child(video_player)
	
	# 5. START PLAYBACK
	if video_stream: video_player.play()
	if sound_stream: audio_player.play()
	
	# 6. START BACKGROUND LOADING
	print("⏳ Background loading Level 0...")
	ResourceLoader.load_threaded_request(TARGET_SCENE)

func _on_video_finished() -> void:
	print("🎬 Cutscene 7 Finished. Resetting Game...")
	
	if video_player: video_player.stop()
	if audio_player: audio_player.stop()
	
	# Ensure the load is actually done
	var status = ResourceLoader.load_threaded_get_status(TARGET_SCENE)
	while status == ResourceLoader.THREAD_LOAD_IN_PROGRESS:
		await get_tree().create_timer(0.1).timeout
		status = ResourceLoader.load_threaded_get_status(TARGET_SCENE)
	
	# TRIGGER RESET
	if GameManager:
		var slot = GameManager.current_save_slot_index if GameManager.current_save_slot_index > 0 else 1
		GameManager.start_new_game(slot)
	else:
		get_tree().change_scene_to_file(TARGET_SCENE)

func _exit() -> void:
	# CRITICAL: Clean up the CanvasLayer when leaving the state
	# If we don't do this, the black screen/video will persist forever.
	if canvas_layer != null:
		canvas_layer.queue_free()
		canvas_layer = null
	
	if audio_player != null:
		audio_player.stop()
		audio_player.queue_free()
