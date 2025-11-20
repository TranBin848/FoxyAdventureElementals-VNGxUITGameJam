extends Area2D

@export var guide_text: String = ""   # Text có thể nhập trong inspector

@onready var label = $RichTextLabel

var shown := false

func _ready():
	var clean_text = guide_text.replace("\\n", "\n")

	label.text = clean_text
	
	# Kết nối signal
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

	# Ẩn ban đầu
	label.modulate.a = 0.0
	label.position.y = -16.0


func _on_body_entered(body):
	if body.name == "Player" and not shown:
		shown = true
		show_text()


func _on_body_exited(body):
	if body.name == "Player":
		shown = false
		hide_text()


func show_text():
	var tween = create_tween()
	tween.parallel().tween_property(label, "modulate:a", 1.0, 0.5).from(0.0)
	tween.parallel().tween_property(label, "position:y", -72.0, 0.5).from(-28.0)


func hide_text():
	var tween = create_tween()
	tween.parallel().tween_property(label, "modulate:a", 0.0, 0.5)
	tween.parallel().tween_property(label, "position:y", -28.0, 1.0)
