extends Area2D
class_name Checkpoint

signal checkpoint_activated(checkpoint_id: String)

@export var checkpoint_id: String = ""

@onready var label = $RichTextLabel
@onready var animated_sprite_2d: AnimatedSprite2D = $AnimatedSprite2D

var is_activated: bool = false
var tween: Tween = null  # Add tween variable


func _ready() -> void:
	if checkpoint_id.is_empty():
		checkpoint_id = str(get_path())
	
	# Initialize label as hidden
	label.visible = false
	label.modulate.a = 0.0
	label.position.y = -16.0

	GameManager.checkpoint_changed.connect(_on_checkpoint_changed)

	if GameManager.current_checkpoint_id == checkpoint_id:
		activate_visual_only()
	else:
		animated_sprite_2d.play("idle")


func _on_body_entered(body: Node2D) -> void:
	if body is Player:
		activate()


func activate() -> void:
	if is_activated:
		return
	is_activated = true

	GameManager.save_checkpoint(checkpoint_id)
	checkpoint_activated.emit(checkpoint_id)
	print("✅ Checkpoint activated:", checkpoint_id)

	animated_sprite_2d.play("active")
	AudioManager.play_sound("checkpoint_activate")
	
	show_text()


func show_text() -> void:
	if tween:
		tween.kill()
		
	label.visible = true
	tween = create_tween()
	tween.parallel().tween_property(label, "modulate:a", 1.0, 0.5).from(0.0)
	tween.parallel().tween_property(label, "position:y", -72.0, 0.5).from(-28.0)
	tween.tween_interval(2.0)
	tween.tween_callback(hide_text)


func hide_text() -> void:
	if tween:
		tween.kill()
	
	tween = create_tween()
	tween.parallel().tween_property(label, "modulate:a", 0.0, 0.5)
	tween.parallel().tween_property(label, "position:y", -88.0, 0.5)


func activate_visual_only() -> void:
	is_activated = true
	animated_sprite_2d.play("active")


func _on_checkpoint_changed(new_id: String) -> void:
	if new_id == checkpoint_id:
		if not is_activated:
			activate_visual_only()
	else:
		is_activated = false
		animated_sprite_2d.play("idle")
