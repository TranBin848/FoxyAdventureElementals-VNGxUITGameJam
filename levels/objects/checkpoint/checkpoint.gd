extends Area2D
class_name Checkpoint

signal checkpoint_activated(checkpoint_id: String)

@export var checkpoint_id: String = ""
@onready var animated_sprite_2d: AnimatedSprite2D = $AnimatedSprite2D

var is_activated: bool = false


func _ready() -> void:
	if checkpoint_id.is_empty():
		checkpoint_id = str(get_path())

	# Kết nối signal từ GameManager
	GameManager.checkpoint_changed.connect(_on_checkpoint_changed)

	# Nếu checkpoint hiện tại trùng với checkpoint trong GameManager
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

	# 🔹 Gọi GameManager để xử lý save
	GameManager.save_checkpoint(checkpoint_id)

	checkpoint_activated.emit(checkpoint_id)
	print("✅ Checkpoint activated:", checkpoint_id)

	animated_sprite_2d.play("active")


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
