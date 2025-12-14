extends ProjectileBase
class_name StunBeamProjectile

# --- Stun Config ---
@export var start_scale: Vector2 = Vector2.ONE
@export var end_scale: Vector2 = Vector2(2.0, 2.0)
@export var scale_duration: float = 0.18
@export var scale_trans := Tween.TRANS_SINE
@export var scale_ease := Tween.EASE_OUT
@export var stun_anim: String = "StunBeam"
@onready var stun_area: Area2D = $StunArea	
@export var knockback_force: float = 300.0
@export var vertical_offset: float = -20.0
@export var stun_duration_sec: float = 1.5
# --- State ---
var exploding: bool = false


func _ready() -> void:
	# Connect animation finished for guaranteed despawn
	if has_node("AnimatedSprite2D"):
		get_node("AnimatedSprite2D").animation_finished.connect(_on_animation_finished, CONNECT_ONE_SHOT)


func _on_hit_area_2d_hitted(area: Variant) -> void:
	_trigger_stun()


func _on_body_entered(body: Node2D) -> void:
	_trigger_stun()


func _trigger_stun() -> void:
	if exploding:
		return
	
	exploding = true
	set_physics_process(false)  # Stop movement when triggered
	
	# Tìm tất cả Enemy trong bán kính vụ nổ
	if stun_area:
		var overlaps = stun_area.get_overlapping_bodies()
		for b in overlaps:
			if b is EnemyCharacter:
				affected_enemies.append(b)
				# Áp dụng trạng thái stun: khóa di chuyển và đổi animation nếu có
				b.is_movable = false
				if b.animated_sprite and b.animated_sprite.animation.contains("stun"):
					b.animated_sprite.play("stun")
				# Hút vào tâm
				b.enter_skill(global_position)
	
	# Reset scale + play animation
	if has_node("AnimatedSprite2D"):
		var sprite = get_node("AnimatedSprite2D")
		sprite.scale = start_scale
		sprite.play(stun_anim)
		
		# LƯU VỊ TRÍ GỐC của Sprite
		var initial_sprite_pos_y = sprite.position.y 
		
		# Stun scale tween
		var tween := create_tween()
		tween.tween_property(
			sprite,
			"scale",
			end_scale,
			scale_duration
		).set_trans(scale_trans).set_ease(scale_ease)

		# TWEEN DỊCH CHUYỂN VỊ TRÍ Y
		tween.tween_property(
			sprite,
			"position:y",
			initial_sprite_pos_y + vertical_offset,
			scale_duration
		).set_trans(scale_trans).set_ease(scale_ease).set_delay(0.0)


func _physics_process(delta: float) -> void:
	if exploding:
		return
	
	super._physics_process(delta)
	rotation = 0


func _on_animation_finished() -> void:
	for e in affected_enemies:
		if e and e.is_inside_tree():
			e.exit_skill()
			# Đẩy enemy văng ra
			e.apply_knockback(global_position, knockback_force)
			# Kết thúc stun sau thời gian định sẵn
			_call_deferred_end_stun(e)
	queue_free()


func _call_deferred_end_stun(enemy: EnemyCharacter) -> void:
	# Tạo timer kết thúc stun độc lập cho từng enemy
	await get_tree().create_timer(stun_duration_sec).timeout
	if enemy and enemy.is_inside_tree():
		enemy.is_movable = true
		# Trả animation về bình thường nếu đang ở "stun"
		if enemy.animated_sprite and enemy.animated_sprite.animation == "stun":
			enemy.change_animation("idle")
