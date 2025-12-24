extends Node
class_name FSMState

## Base state class for Finite State Machine states

var fsm: FSM = null
var obj: BaseCharacter = null
var timer: float = 0.0

func _enter() -> void:
	pass

func _exit() -> void:
	pass

func _update( _delta ):
	pass

# Update timer and return true if timer is finished
func update_timer(delta: float) -> bool:
	if timer <= 0:
		return false
	timer -= delta
	if timer <= 0:
		return true
	return false


func change_state(new_state: FSMState) -> void:
	fsm.change_state(new_state)
	
func get_current_anim_duration() -> float:
	# 1. Get the SpriteFrames resource
	var sprite_frames = obj.animated_sprite.sprite_frames
	var current_anim = obj.animated_sprite.animation
	
	# 2. Guard clause: Check if animation exists
	if not sprite_frames.has_animation(current_anim):
		return 0.0
	
	# 3. Get Frame Count and Speed (FPS)
	var frame_count = sprite_frames.get_frame_count(current_anim)
	var fps = sprite_frames.get_animation_speed(current_anim)
	
	# 4. Handle Speed Scale (if you changed the playback speed on the node)
	var actual_fps = fps *  obj.animated_sprite.speed_scale
	
	# Avoid division by zero
	if actual_fps == 0:
		return 0.0
		
	# 5. Calculate Duration (Frames / FPS)
	return frame_count / actual_fps
