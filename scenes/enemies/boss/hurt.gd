extends KingCrabState
@onready var hurt_box: CollisionShape2D = $"../../Direction/HurtArea2D/CollisionShape2D2"
@onready var collision: CollisionShape2D = $"../../CollisionShape2D"
@onready var hit_box: CollisionShape2D = $"../../Direction/HitArea2D/CollisionShape2D"

func _enter() -> void:
	obj.handle_dead()
	obj.change_animation("die")
	Engine.time_scale = 0.2
	timer = get_current_anim_duration()

func _update(_delta: float) -> void:
	if update_timer(_delta):
		Engine.time_scale = 1.0
