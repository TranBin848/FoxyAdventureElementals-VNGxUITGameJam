extends AreaBase

@export var knockback_force: float = 350.0

func _ready() -> void:
	anim_player = get_node_or_null("AnimationPlayer")
	if not anim_player:
		return

	anim_player.play("ThunderStrike")
		
	AudioManager.play_sound("skill_thunderstrike_crackle")
	
# Called by AnimationPlayer method track when startup animation completes
func _on_startup_complete() -> void:
	AudioManager.play_sound("skill_thunderstrike")
	_enable_hitbox()  # Enable damage detection

# Called by AnimationPlayer method track at knockback frame
func _apply_stun_effect() -> void:
	queue_free()
