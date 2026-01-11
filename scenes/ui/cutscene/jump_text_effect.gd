# res://scripts/jump_text_effect.gd
@tool
extends RichTextEffect
class_name RichTextJump

# Define the tag name
var bbcode = "jump"

# === THE FIX: A public variable we can Tween from the outside ===
var current_limit: float = 0.0

func _process_custom_fx(char_fx: CharFXTransform) -> bool:
	# 1. HIDE FUTURE CHARACTERS
	# Compare index against our public variable 'current_limit'
	if char_fx.relative_index > int(current_limit):
		char_fx.color.a = 0
		return true # Keep processing (important for updates)
		
	# 2. ANIMATE CURRENT CHARACTER
	var diff = current_limit - char_fx.relative_index
	
	if diff >= 0 and diff < 1.0:
		# Fade In
		char_fx.color.a = diff 
		
		# Jump Up
		# You can still use env.get() for constants like height/speed
		var height = char_fx.env.get("height", 10.0)
		var y_offset = (1.0 - diff) * height 
		
		char_fx.offset.y += y_offset
		
	return true
