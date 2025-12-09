extends Area2D

@export var guide_text: String = ""   # Text có thể nhập trong inspector

@onready var label = $RichTextLabel

var shown := false
var tween : Tween = null

func _ready():
	var clean_text = guide_text.replace("\\n", "\n")

	label.text = clean_text

	# Ẩn ban đầu
	label.modulate.a = 0.0
	label.position.y = -16.0


func _on_body_entered(body):
	if body.name == "Player" and not shown:
		shown = true
		AudioManager.play_sound("guide_enter")
		show_text()


func _on_body_exited(body):
	if body.name == "Player":
		shown = false
		AudioManager.play_sound("guide_exit")
		hide_text()


func show_text():
	if tween:
		tween.kill()  # Kill existing tween before creating new one
	
	tween = create_tween()
	tween.parallel().tween_property(label, "modulate:a", 1.0, 0.5).from(0.0)
	tween.parallel().tween_property(label, "position:y", -72.0, 0.5).from(-28.0)

func hide_text():
	if tween:
		tween.kill()  # Kill existing tween before creating new one
	
	tween = create_tween()
	tween.parallel().tween_property(label, "modulate:a", 0.0, 0.5)
	tween.parallel().tween_property(label, "position:y", -28.0, 1.0)
