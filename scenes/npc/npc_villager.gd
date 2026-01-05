extends Node2D

@export var hoithoai: String

func _ready() -> void:
	Dialogic.signal_event.connect(_on_dialog_signal)

func _on_interactive_area_2d_interacted() -> void:
	Dialogic.start(hoithoai)

func _on_dialog_signal(argument):
	if argument == "npc_vanish" and hoithoai == "guide_elemental":
		vanish()

func vanish() -> void:
	var tween = create_tween()
	tween.tween_property(self, "modulate:a", 0.0, 1.0) # fade-out 1 giây
	await tween.finished
	queue_free()
