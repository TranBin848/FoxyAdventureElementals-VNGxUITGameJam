extends CanvasLayer
signal text_finished

@onready var label: RichTextLabel = $DialogText
@onready var type_sound: AudioStreamPlayer = $TypeSound
@onready var continue_indicator: Sprite2D = $ContinueIndicator  # Can be Label, TextureRect, AnimatedSprite, etc.

# Configuration
var typing_speed: float = 0.02
var current_tween: Tween

# === THE FIX: Hold a reference to the specific effect instance ===
var jump_effect_instance: RichTextJump = null

# Typewriter sound configuration
var pitch_min: float = 0.95
var pitch_max: float = 1.05
var volume_variation: float = 3.0  # dB variation
var base_volume: float = -17.0  # Base volume in dB

# Track the parsed text for character detection
var parsed_text: String = ""
var is_waiting_for_input: bool = false
var is_typing: bool = false

func _ready() -> void:
	# 1. Create the effect instance
	jump_effect_instance = RichTextJump.new()
	
	# 2. Install it into the label manually
	label.install_effect(jump_effect_instance)
	
	# Set base volume
	type_sound.volume_db = base_volume
	
	# Hide continue indicator initially
	if continue_indicator:
		continue_indicator.visible = false
	
	# Hide UI initially
	visible = false

func show_text(text: String, wait_time_after: float = 1.0) -> void:
	visible = true
	is_waiting_for_input = false
	is_typing = true
	
	# Hide continue indicator while typing
	if continue_indicator:
		continue_indicator.visible = false
	
	# Reset the limit on our effect instance
	jump_effect_instance.current_limit = 0.0
	
	# Apply the text with the tag
	label.text = "[center][jump height=20.0]" + text + "[/jump][/center]"
	
	# Force label to 'show' everything so the effect controls visibility
	label.visible_ratio = 1.0 
	
	# Store parsed text for character checking
	parsed_text = label.get_parsed_text()
	
	var char_count = parsed_text.length()
	var duration = char_count * typing_speed
	
	if current_tween: current_tween.kill()
	current_tween = create_tween()
	
	# === THE FIX: Tween the PROPERTY on the EFFECT INSTANCE ===
	current_tween.tween_property(jump_effect_instance, "current_limit", float(char_count), duration)
	
	# Add the sound callback logic with typewriter effect
	current_tween.parallel().tween_method(_handle_typewriter_sound, 0.0, float(char_count), duration)
	
	current_tween.tween_interval(wait_time_after)
	current_tween.tween_callback(_on_sequence_finished)

var last_char_index: int = -1

func _handle_typewriter_sound(value: float) -> void:
	var idx = int(value)
	
	# Only play sound when a NEW character appears
	if idx > last_char_index:
		# Check if the character is NOT a space or whitespace
		if idx < parsed_text.length():
			var current_char = parsed_text[idx]
			
			# Only play sound for visible characters (not spaces, tabs, newlines)
			if not current_char in [' ', '\t', '\n', '\r']:
				# Randomize pitch for mechanical typewriter feel
				type_sound.pitch_scale = randf_range(pitch_min, pitch_max)
				
				# Randomize volume slightly (some keys hit harder than others)
				type_sound.volume_db = base_volume + randf_range(-volume_variation, volume_variation)
				
				type_sound.play()
		
		last_char_index = idx

func _on_sequence_finished() -> void:
	last_char_index = -1
	parsed_text = ""
	is_typing = false
	is_waiting_for_input = true
	
	# Show continue indicator
	if continue_indicator:
		continue_indicator.visible = true
		_animate_continue_indicator()

func _animate_continue_indicator() -> void:
	# Optional: Add a pulsing/blinking animation to the indicator
	if not continue_indicator:
		return
		
	var anim_tween = create_tween().set_loops()
	anim_tween.tween_property(continue_indicator, "modulate:a", 0.3, 0.5)
	anim_tween.tween_property(continue_indicator, "modulate:a", 1.0, 0.5)

func _input(event: InputEvent) -> void:
	# Only accept input when text is completely finished displaying
	if not is_waiting_for_input:
		return
		
	# Accept any key press or mouse click
	if event.is_action_pressed("ui_accept") or \
	   event.is_action_pressed("ui_select") or \
	   (event is InputEventMouseButton and event.pressed) or \
	   (event is InputEventKey and event.pressed):
		is_waiting_for_input = false
		if continue_indicator:
			continue_indicator.visible = false
		text_finished.emit()
