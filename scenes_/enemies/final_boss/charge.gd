extends BlackEmperorState

@export var charge_duration: float = 5.0  # Thời gian sạc trên mặt đất
@export var fly_up_duration: float = 1.0  # Thời gian bay lên
@export var hover_duration: float = 10.0  # Thời gian đứng im trên trời

# Skill bay có thể dùng sau khi charge
var fly_skills = ["flylightning", "rainbullets"]

func _enter() -> void:
	# Boss đứng im trên mặt đất
	obj.velocity = Vector2.ZERO
	obj.is_movable = false
	obj.ignore_gravity = true
	
	# Play animation charge
	if obj.animated_sprite_2d:
		if obj.animated_sprite_2d.sprite_frames.has_animation("charge"):
			obj.animated_sprite_2d.play("charge")
		elif obj.animated_sprite_2d.sprite_frames.has_animation("idle"):
			obj.animated_sprite_2d.play("idle")
	
	print("Boss charging for ", charge_duration, " seconds...")
	
	# Đợi charge_duration giây (sạc năng lượng)
	await get_tree().create_timer(charge_duration).timeout
	
	# === BAY LÊN TRỜI ===
	print("Boss flying up...")
	
	# Play animation bay
	if obj.animated_sprite_2d and obj.animated_sprite_2d.sprite_frames.has_animation("fly"):
		obj.animated_sprite_2d.play("fly")
	
	# Bay lên độ cao fly_target_y
	var target_pos = Vector2(obj.global_position.x, obj.fly_target_y)
	var tween = create_tween()
	tween.tween_property(obj, "global_position", target_pos, fly_up_duration).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	await tween.finished
	
	# === ĐỨNG IM TRÊN TRỜI ===
	print("Boss hovering for ", hover_duration, " seconds...")
	
	# Play animation hover/idle
	if obj.animated_sprite_2d:
		if obj.animated_sprite_2d.sprite_frames.has_animation("hover"):
			obj.animated_sprite_2d.play("hover")
		elif obj.animated_sprite_2d.sprite_frames.has_animation("fly"):
			obj.animated_sprite_2d.play("fly")
	
	# Đợi hover_duration giây
	await get_tree().create_timer(hover_duration).timeout
	
	# === DÙNG 1 TRONG 2 SKILL BAY ===
	# Random chọn 1 skill: flylightning hoặc rainbullets
	var random_skill = fly_skills[randi() % fly_skills.size()]
	print("Boss using skill: ", random_skill)
	
	obj.is_movable = true
	
	# Chuyển sang skill đã chọn
	if fsm.states.has(random_skill):
		fsm.change_state(fsm.states[random_skill])
	else:
		print("Skill not found: ", random_skill)
		fsm.change_state(fsm.states.walk)

func _exit() -> void:
	obj.is_movable = true
