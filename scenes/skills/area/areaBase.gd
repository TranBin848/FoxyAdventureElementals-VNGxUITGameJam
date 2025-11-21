extends Area2D
class_name AreaBase # Đây là lớp cơ sở

var startupanim: AnimatedSprite2D
var targetenemy: EnemyCharacter

var damage: int
var elemental_type: int
var duration: float
var targets_in_area: Array = [] # Lưu trữ kẻ địch đang ở trong vùng

var timer: Timer

## ✅ Hàm setup cơ bản, các lớp con có thể override và gọi super.setup
func setup(skill: Skill, caster_position: Vector2, enemy: EnemyCharacter) -> void:
	self.damage = skill.damage
	self.elemental_type = skill.elemental_type
	self.duration = skill.duration
	self.global_position = caster_position
	var hit_area: HitArea2D = null
	targetenemy = enemy
	if has_node("HitArea2D"):
		hit_area = $HitArea2D
		hit_area.damage = damage
		hit_area.elemental_type = elemental_type
		#print("✅ Gán HitArea cho WaterTornado:", damage, elemental_type)
	
	if has_node("StartupAnimatedSprite2D"):
		startupanim = $StartupAnimatedSprite2D
		var callback = Callable(self, "_on_startup_animation_finished").bind(skill)
		startupanim.animation_finished.connect(callback)
		
		startupanim.play("startup")
		if has_node("AnimatedSprite2D"):
			$AnimatedSprite2D.stop()       # <-- Dừng animation
			$AnimatedSprite2D.visible = false # <-- Ẩn Node
			
		if hit_area:
			print("Check")
			# Sử dụng 'monitoring' = false để vô hiệu hóa Area2D nhận tín hiệu
			hit_area.monitoring = false
	else:
		# Play animation if có AnimatedSprite2D
		if has_node("AnimatedSprite2D"):
			$AnimatedSprite2D.play(skill.animation_name)
	
	
	# === KHỞI TẠO VÀ CHẠY TIMER TỰ HỦY ===
	_setup_duration_timer()
# --- Signal Callbacks ---

func _on_startup_animation_finished(skill: Skill):
	# 1. Dừng và ẩn animation khởi động
	startupanim.stop()
	startupanim.visible = false
	
	if has_node("HitArea2D"):
		$HitArea2D.monitoring = true
	
	# 2. Hiển thị animation chính
	$AnimatedSprite2D.visible = true
	$AnimatedSprite2D.play(skill.animation_name)

	
func _setup_duration_timer() -> void:
	await ready

	timer = Timer.new()
	timer.wait_time = max(duration, 0.01)
	timer.one_shot = true
	add_child(timer)

	timer.timeout.connect(Callable(self, "_on_duration_finished"))
	timer.start()

func _on_duration_finished() -> void:
	print("Skill expired:", self)
	queue_free()
	
func play(animation_name: String):
	$AnimatedSprite2D.play(animation_name)
