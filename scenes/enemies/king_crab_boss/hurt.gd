extends KingCrabState
@onready var hurt_box: CollisionShape2D = $"../../Direction/HurtArea2D/CollisionShape2D2"
@onready var collision: CollisionShape2D = $"../../CollisionShape2D"
@onready var hit_box: CollisionShape2D = $"../../Direction/HitArea2D/CollisionShape2D"

const CHEST_DROP_SCENE: PackedScene = preload("res://levels/objects/chest/boss_chest.tscn")

func _enter() -> void:
	obj.handle_dead()
	obj.change_animation("die")
	obj.animated_sprite.animation_finished.connect(_spawn_chest)
	Engine.time_scale = 0.2
	timer = get_current_anim_duration()

func _update(_delta: float) -> void:
	if update_timer(_delta):
		Engine.time_scale = 1.0
		
	
func _spawn_chest() -> void:
	var chest_drop = CHEST_DROP_SCENE.instantiate() as BossChest
	get_tree().current_scene.add_child(chest_drop)
	chest_drop.drop_wand_level = Player.WandLevel.SORROW
	chest_drop.global_position = obj.global_position
