extends PlayerState


func _enter() -> void:
	#Change animation to attack
	obj.change_animation("jump attack")
	AudioManager.play_sound("player_attack")

	#Enable collision shape of hit area
	obj.get_node("Direction/HitArea2D/CollisionShape2D").disabled = false
	
	#add fx
	var slash_fx = obj.slash_fx_factory.create() as Node2D
	slash_fx.position = Vector2.ZERO
	
	print(obj.animated_sprite.name)
	await obj.animated_sprite.animation_finished
	call_deferred("change_state", fsm.previous_state)
	#change_state()
	
func _update(_delta: float) -> void:
	#stop moving if landed mid jump attack animation
	if obj.is_on_floor():
		obj.velocity.x = 0

func _exit() -> void:
	#Disable collision shape of hit area
	obj.get_node("Direction/HitArea2D/CollisionShape2D").disabled = true
	obj.start_atk_cd()

#func _update(delta: float) -> void:
	##If attack is finished change to previous state
	#if update_timer(delta):
		#change_state(fsm.previous_state)
