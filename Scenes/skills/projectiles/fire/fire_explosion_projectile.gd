extends ProjectileBase
class_name FireExplosionProjectile

# --- Explosion Config ---
@export var start_scale: Vector2 = Vector2.ONE
@export var end_scale: Vector2 = Vector2(2.0, 2.0)
@export var scale_duration: float = 0.18
@export var scale_trans := Tween.TRANS_SINE
@export var scale_ease := Tween.EASE_OUT
@export var explosion_anim: String = "FireExplosion_End"
@onready var explosion_area: Area2D = $ExplosionArea	
@export var knockback_force: float = 400.0 # Lực đẩy văng kẻ địch ra sau khi hút
@export var vertical_offset: float = -30.0
# --- State ---
var exploding: bool = false


func _on_hit_area_2d_hitted(area: Variant) -> void:
	_trigger_explosion()


func _on_body_entered(body: Node2D) -> void:
	_trigger_explosion()


func _trigger_explosion() -> void:
	if exploding:
		return
	
	exploding = true
	#set_physics_process(false)
	
	# Tìm tất cả Enemy trong bán kính vụ nổ
	var overlaps = explosion_area.get_overlapping_bodies()
	print(overlaps)
	for b in overlaps:
		if b is EnemyCharacter:
			affected_enemies.append(b)
			b.enter_tornado(global_position)   # hút vào tâm
	
	# Reset scale + play animation
	$AnimatedSprite2D.scale = start_scale
	$AnimatedSprite2D.play(explosion_anim)
	
	# LƯU VỊ TRÍ GỐC của Sprite để phục vụ cho Tween
	var initial_sprite_pos_y = $AnimatedSprite2D.position.y 
	
	# Explosion scale tween (giữ nguyên)
	var tween := create_tween()
	tween.tween_property(
		$AnimatedSprite2D,
		"scale",
		end_scale,
		scale_duration
	).set_trans(scale_trans).set_ease(scale_ease)

	# <-- THÊM TWEEN DỊCH CHUYỂN VỊ TRÍ Y
	tween.tween_property(
		$AnimatedSprite2D,
		"position:y",
		initial_sprite_pos_y + vertical_offset, # Dịch chuyển Y lên trên
		scale_duration
	).set_trans(scale_trans).set_ease(scale_ease).set_delay(0.0)
	
	# Cleanup (giữ nguyên)
	$AnimatedSprite2D.connect(
		"animation_finished",
		Callable(self, "_on_animation_finished"),
		CONNECT_ONE_SHOT
	)


func _physics_process(delta: float) -> void:
	if exploding:
		return
	
	super._physics_process(delta)
	
	rotation = 0


func _on_animation_finished() -> void:
	for e in affected_enemies:
		if e and e.is_inside_tree():
			e.exit_tornado()

			# Đẩy enemy văng ra
			e.apply_knockback(global_position, knockback_force)
	queue_free()
