extends WarLordState

const CHEST_DROP_SCENE: PackedScene = preload("res://levels/objects/chest/boss_chest.tscn")

func _enter() -> void:
	AudioManager.play_sound("war_lord_defeat")
	obj.handle_dead()
	obj.change_animation("die")
	obj.animated_sprite.animation_finished.connect(_spawn_chest)
	
func _spawn_chest() -> void:
	if not obj.being_controled:
		var chest_drop = CHEST_DROP_SCENE.instantiate() as BossChest
		get_tree().current_scene.add_child(chest_drop)
		chest_drop.drop_wand_level = Player.WandLevel.SOUL
		chest_drop.global_position = obj.global_position
