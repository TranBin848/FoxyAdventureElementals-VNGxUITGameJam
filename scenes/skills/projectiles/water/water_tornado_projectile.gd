extends ProjectileBase
class_name WaterTornadoProjectile

@export var tornado_duration: float = 3.0 # <-- THỜI GIAN LỐC XOÁY TỒN TẠI
@export var knockback_force: float = 400.0 # Lực đẩy văng kẻ địch ra sau khi hút
@onready var explosion_area: Area2D = $ExplosionArea	
@export var explosion_anim: String = "TornadoExplosion_End"
# --- State ---
var exploding: bool = false
var time_elapsed: float = 0.0 # <-- Biến đếm thời gian

func _physics_process(delta: float) -> void:
	super._physics_process(delta)
	
	if exploding:
		time_elapsed += delta
		
		if time_elapsed >= tornado_duration:
			return
	
	

# Callback khi có va chạm với enemy
func _on_hit_area_2d_hitted(area: Variant) -> void:
	_trigger_explosion()
		

func _on_body_entered(body: Node2D) -> void:
	_trigger_explosion()


func _trigger_explosion() -> void:
	if exploding:
		return
	
	exploding = true
	
	# Tìm tất cả Enemy trong bán kính vụ nổ
	var overlaps = explosion_area.get_overlapping_bodies()
	print(overlaps)
	for b in overlaps:
		if b is EnemyCharacter:
			affected_enemies.append(b)
			b.enter_tornado(global_position)   # hút vào tâm
	
	$AnimatedSprite2D.play(explosion_anim)
	
	# Cleanup (giữ nguyên)
	$AnimatedSprite2D.connect(
		"animation_finished",
		Callable(self, "_on_animation_finished"),
		CONNECT_ONE_SHOT
	)

func _on_animation_finished() -> void:
	for e in affected_enemies:
		if e and e.is_inside_tree():
			e.exit_tornado()

			# Đẩy enemy văng ra
			e.apply_knockback(global_position, knockback_force)
	queue_free()
