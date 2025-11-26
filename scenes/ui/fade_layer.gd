extends CanvasLayer
@onready var color_rect: ColorRect = $ColorRect

func _ready():
	color_rect.color.a = 0.0
	add_to_group("FadeLayer")

func fade_out(duration := 0.5):
	var tween = create_tween()
	tween.tween_property(color_rect, "color:a", 1.0, duration)
	await tween.finished

func fade_in(duration := 0.5):
	var tween = create_tween()
	tween.tween_property(color_rect, "color:a", 0.0, duration)
	await tween.finished
