extends Control
signal finished(success)

@export var keyString: String = "Q"
@export var keyCode: Key = KEY_Q
@export var eventDuration := 1.5
@export var displayDuration := 1.5

@onready var color_rect: ColorRect = %ColorRect
@onready var key_label: Label = %KeyLabel
@onready var success_label: Label = %SuccessLabel
@onready var failed_label: Label = %FailedLabel

var tween: Tween
var success = false
var has_emitted = false 

func _ready() -> void:
	add_to_group("QTE")
	key_label.text = keyString
	
	success_label.hide()
	failed_label.hide()
	
	tween = create_tween()
	await _animation()
	
	if not success and not has_emitted:
		has_emitted = true
		key_label.hide()
		failed_label.show() 
		finished.emit(false) 
	
	# ✅ FIX 2: Make the cleanup timer ignore time scale too
	# Use 'true' for the 4th argument (ignore_time_scale)
	await get_tree().create_timer(displayDuration, true, false, true).timeout
	
	hide()
	queue_free()

func _animation():
	# ✅ FIX 1: Calculate "Game Time" needed to match "Real Time"
	# If time_scale is 0.1, we only need 0.15 game seconds to equal 1.5 real seconds.
	var current_scale = Engine.time_scale
	if current_scale <= 0: current_scale = 1.0 # Safety check
	
	var adjusted_duration = eventDuration * current_scale
	
	tween.tween_property(color_rect, "material:shader_parameter/value", 0, adjusted_duration)
	await tween.finished

func _input(_event: InputEvent) -> void:
	if has_emitted or success:
		return
	
	if Input.is_key_pressed(keyCode):
		success = true
		has_emitted = true
		success_label.show()
		key_label.hide()
		
		if tween and tween.is_valid():
			tween.kill()
		
		finished.emit(true)
