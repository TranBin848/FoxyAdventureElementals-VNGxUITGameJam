extends PlayerState

func _enter() -> void:
	#Change animation to attack
	obj.change_animation("attack")
	AudioManager.play_sound("player_attack")
	obj.velocity.x = 0
	
	var hit_area_2d = obj.get_node("Direction/HitArea2D")
	
	#Enable collision shape of hit area
	if obj.current_weapon == obj.WeaponType.BLADE:
		hit_area_2d.damage = 5
	elif obj.current_weapon == obj.WeaponType.WAND:
		hit_area_2d.damage = 1
	obj.get_node("Direction/HitArea2D/CollisionShape2D").disabled = false
	
	#add fx
	var slash_fx = obj.slash_fx_factory.create() as Node2D
	slash_fx.position = Vector2.ZERO

	await obj.animated_sprite.animation_finished
	change_state(fsm.previous_state)

func _exit() -> void:
	#Disable collision shape of hit area
	obj.get_node("Direction/HitArea2D/CollisionShape2D").disabled = true
	obj.start_atk_cd()

#func _update(delta: float) -> void:
	##If attack is finished change to previous state
	#if update_timer(delta):
		#change_state(fsm.previous_state)
