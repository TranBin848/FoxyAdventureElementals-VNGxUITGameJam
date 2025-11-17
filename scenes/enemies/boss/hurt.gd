extends KingCrabState
@onready var hurt_box: CollisionShape2D = $"../../Direction/HurtArea2D/CollisionShape2D2"
@onready var collision: CollisionShape2D = $"../../CollisionShape2D"
@onready var hit_box: CollisionShape2D = $"../../Direction/HitArea2D/CollisionShape2D"

func _enter() -> void:
	hurt_box.disabled = true
	collision.disabled = true
	hit_box.disabled = true
	obj.gravity = 0
	obj.velocity.x = 0
	obj.change_animation("die")
	Engine.time_scale = 0.2
	await $"../../Direction/AnimatedSprite2D".animation_finished
	Engine.time_scale = 1.0
