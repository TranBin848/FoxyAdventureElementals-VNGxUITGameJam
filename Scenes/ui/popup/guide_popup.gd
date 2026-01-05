extends MarginContainer
class_name TutorialPopup

@onready var video_player: VideoStreamPlayer = $NinePatchRect/VideoStreamPlayer
# 1. Add reference to the new TextureRect
@onready var texture_rect: TextureRect = $NinePatchRect/TextureRect 
@onready var label: Label = $NinePatchRect/Label
@onready var content_label: RichTextLabel = $NinePatchRect/Content
@onready var close_button: TextureButton = $NinePatchRect/CloseTextureButton

func _ready():
	process_mode = Node.PROCESS_MODE_ALWAYS 
	get_tree().paused = true
	
	close_button.pressed.connect(_on_close_texture_button_pressed)
	
	# Only auto-play if the video player was set up in the editor and is visible
	if video_player.stream and video_player.visible:
		video_player.play()

# 2. Update setup to accept an optional image_path
func setup(title_text: String, description_text: String, video_path: String = "", image_path: String = "") -> void:
	if not is_inside_tree(): await ready
	
	label.text = title_text
	content_label.text = description_text
	
	# Reset both to hidden initially
	video_player.hide()
	video_player.stop() # Stop any previous video
	texture_rect.hide()
	
	# --- OPTION A: Video Provided ---
	if video_path != "":
		var stream = load(video_path)
		if stream:
			video_player.stream = stream
			video_player.show()
			video_player.play()
			
	# --- OPTION B: Image Provided (only if no video) ---
	elif image_path != "":
		var texture = load(image_path)
		if texture:
			texture_rect.texture = texture
			texture_rect.show()
			
			# 3. Configure scaling to "Fit Frame" proportionally
			texture_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			texture_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED

func _exit_tree() -> void:
	get_tree().paused = false
	
func hide_popup():
	queue_free()
		
func _on_overlay_color_rect_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		hide_popup()

func _on_close_texture_button_pressed() -> void:
	hide_popup()
