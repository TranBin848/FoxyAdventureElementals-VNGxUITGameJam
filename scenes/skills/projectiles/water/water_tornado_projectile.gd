extends ProjectileBase
class_name WaterTornadoProjectile

@export var tornado_duration: float = 3.0 # <-- THỜI GIAN LỐC XOÁY TỒN TẠI
@export var knockback_force: float = 300.0 # Lực đẩy văng kẻ địch ra sau khi hút
@onready var explosion_area: Area2D = $ExplosionArea	
@export var explosion_anim: String = "WaterTornado_End"

@onready var duration_timer: Timer = Timer.new()
# --- State ---
var exploding: bool = false
var ending: bool = false # Cờ báo hiệu đang chạy animation kết thúc

func _ready() -> void:
	# 1. Khởi tạo Timer và kết nối tín hiệu
	duration_timer.one_shot = true
	duration_timer.wait_time = tornado_duration
	duration_timer.timeout.connect(_start_ending_sequence)
	add_child(duration_timer)

func _physics_process(delta: float) -> void:
	if exploding:
		return
	
	super._physics_process(delta)
	
# --- Bắt đầu quá trình kết thúc (SAU KHI HẾT THỜI GIAN) ---
func _start_ending_sequence() -> void:
	if ending:
		return
		
	ending = true
	
	# Dừng Timer để tránh việc kích hoạt lại
	duration_timer.stop()
	# Dừng di chuyển và logic vật lý của ProjectileBase
	set_physics_process(false) 
	
	# Chơi animation kết thúc
	$AnimatedSprite2D.play(explosion_anim)
	
	# Kết nối hàm dọn dẹp vào animation kết thúc
	$AnimatedSprite2D.connect(
		"animation_finished",
		Callable(self, "_on_animation_finished"),
		CONNECT_ONE_SHOT
	)

# Callback khi có va chạm với enemy
func _on_hit_area_2d_hitted(area: Variant) -> void:
	_trigger_explosion()
		

func _on_body_entered(body: Node2D) -> void:
	if $AnimatedSprite2D.animation != "WaterTornado_End":
		# Nếu đụng vật tĩnh, ta bắt đầu animation kết thúc ngay lập tức (không đợi 3s)
		_start_ending_sequence() 
		# Dòng set_physics_process(false) đã được chuyển vào _start_ending_sequence()


func _trigger_explosion() -> void:
	if exploding:
		return
	
	exploding = true
	
	duration_timer.start()
	
	# Tìm tất cả Enemy trong bán kính vụ nổ
	var overlaps = explosion_area.get_overlapping_bodies()
	print(overlaps)
	for b in overlaps:
		if b is EnemyCharacter:
			affected_enemies.append(b)
			b.enter_skill(global_position)   # hút vào tâm


func _on_animation_finished() -> void:
	for e in affected_enemies:
		if e and e.is_inside_tree():
			e.exit_skill()

			# Đẩy enemy văng ra
			e.apply_knockback(global_position, knockback_force)
	queue_free()

	

func _on_explosion_area_body_entered(body: Node2D) -> void:
	# 1. Nếu lốc xoáy đã kết thúc, không làm gì cả
	if ending:
		return
		
	# 2. Xử lý Va Chạm với Enemy (HÚT KẺ ĐỊCH VÀO)
	if exploding and body is EnemyCharacter:
		# KIỂM TRA: Nếu Enemy chưa có trong danh sách
		if not affected_enemies.has(body):
			affected_enemies.append(body)
			body.enter_skill(global_position) # hút vào tâm
