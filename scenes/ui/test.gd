extends MarginContainer

func _ready() -> void:
	$HBoxContainer/TextureButton.pressed.connect(_on_pressed)

func _on_pressed() -> void:
	print("hello")
