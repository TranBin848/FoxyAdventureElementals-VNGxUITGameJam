extends MarginContainer
class_name TutorialPopup

@onready var video_player: VideoStreamPlayer = $NinePatchRect/VideoStreamPlayer
@onready var label: Label = $NinePatchRect/Label
@onready var content_label: RichTextLabel = $NinePatchRect/Content # Assumed this is a Label or RichTextLabel
@onready var close_button: TextureButton = $NinePatchRect/CloseTextureButton

func _ready():
	# Ensure the popup processes even when game is paused
	process_mode = Node.PROCESS_MODE_ALWAYS 
	get_tree().paused = true
	
	close_button.pressed.connect(_on_close_texture_button_pressed)
	
	# Start video if one is loaded
	if video_player.stream:
		video_player.play()

func setup(title_text: String, description_text: String, video_path: String = "") -> void:
	# We use call_deferred or await ready to ensure nodes are initialized before setting text
	if not is_inside_tree(): await ready
	
	label.text = title_text
	content_label.text = description_text
	
	if video_path != "":
		var stream = load(video_path)
		if stream:
			video_player.stream = stream
			video_player.play()
		else:
			video_player.hide()
	else:
		video_player.hide()

func _exit_tree() -> void:
	get_tree().paused = false
	
func hide_popup():
	queue_free()
		
func _on_overlay_color_rect_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		hide_popup()

func _on_close_texture_button_pressed() -> void:
	hide_popup()
