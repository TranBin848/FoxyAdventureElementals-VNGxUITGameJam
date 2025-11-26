# res://items/SkillDrop.gd
extends Area2D
class_name SkillDrop

# Node Skill Resource (được truyền vào từ Enemy)
var skill_resource_class: Script = null
var skill_name: String = ""
var skill_texture_path: String = ""

@onready var sprite: Sprite2D = $Sprite2D
@export var float_speed: float = 30.0 # Tốc độ item nhấp nhô

@export var attract_speed: float = 300.0 # Tốc độ bay về Player khi bị hút
var is_attracted: bool = false
var target_player: Player = null # Lưu trữ Player đang hút vật phẩm

var float_tween: Tween = null # ⬅️ Biến để lưu trữ Tween

func _ready() -> void:
	# Kết nối tín hiệu va chạm
	body_entered.connect(_on_body_entered)
	
	# Cài đặt hình ảnh sau khi khởi tạo (nếu có path)
	if not skill_texture_path.is_empty():
		sprite.texture = load(skill_texture_path)
	
	var tween = create_tween() # Tạo Tween trên SkillDrop (self)
	float_tween = tween # ⬅️ Lưu lại tham chiếu
	tween.set_loops()
	
	# Hiệu ứng nhấp nhô nhẹ
	tween.set_loops()
	tween.tween_property(self, "position:y", position.y - 5, 1.0).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(self, "position:y", position.y + 5, 1.0).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)


func setup_drop(resource_class: Script, name: String, texture_path: String) -> void:
	self.skill_resource_class = resource_class
	self.skill_name = name
	self.skill_texture_path = texture_path
	
	# Cài đặt hình ảnh nếu được gọi sau _ready
	if is_node_ready():
		sprite.texture = load(skill_texture_path)

func _physics_process(delta: float) -> void:
	# Logic nhấp nhô nhẹ đã được xử lý bằng Tween trong _ready()
	
	# 🎯 Logic bay theo Player (Attraction Mode)
	if is_attracted and is_instance_valid(target_player):
		var direction = (target_player.global_position - global_position + Vector2(0,-15)).normalized()
		global_position += direction * attract_speed * delta
		
		# Kiểm tra nếu đã đủ gần để nhặt (Auto-collect check)
		if global_position.distance_to(target_player.global_position) < 10:
			_collect_item(target_player)

func _on_body_entered(body: Node2D):
	## Hàm này vẫn dùng cho va chạm vật lý để nhặt tức thì (nếu không dùng auto-collect)
	#if not is_attracted and body is Player:
	_collect_item(body as Player)

# Hàm mới để xử lý việc nhặt (được gọi từ _on_body_entered HOẶC _physics_process)
func _collect_item(player: Player) -> void:
	var success = player.add_new_skill(skill_resource_class)
	
	if success:
		# Phát hiệu ứng phân mảnh/hút (Bước 3)
		#_play_collect_effect()
		
		# Tự hủy
		queue_free()

func _play_collect_effect() -> void:
	# Ẩn CollisionShape để Player không thể kích hoạt lại va chạm
	$CollisionShape2D.disabled = true 
	
	# Dừng logic bay theo để bắt đầu animation cuối
	is_attracted = false
	
	var tween = create_tween()
	
	# Chạy đồng thời: Thu nhỏ, mờ dần, và di chuyển nhanh về Player
	
	# 1. Thu nhỏ và mờ dần (Fade out)
	tween.parallel().tween_property(sprite, "scale", Vector2(0.1, 0.1), 0.2)
	tween.parallel().tween_property(sprite, "modulate:a", 0.0, 0.2)
	
	# 2. Di chuyển nhanh đến vị trí Player (hoặc một điểm trên Player)
	var final_position = target_player.global_position + Vector2(0, 50) # Ví dụ: bay vào tim Player
	tween.parallel().tween_property(self, "global_position", final_position, 1.0)
	
	# Tự hủy sau khi hiệu ứng kết thúc
	tween.tween_callback(queue_free)

func _on_detection_player_area_2d_body_entered(body: Node2D):
	if body is Player:
		target_player = body as Player
		is_attracted = true
		# Dừng hiệu ứng nhấp nhô khi bắt đầu bị hút
		if float_tween and float_tween.is_valid():
			float_tween.stop()

func _on_detection_player_area_2d_body_exited(body: Node2D):
	if body is Player and body == target_player:
		target_player = null
		is_attracted = false
		# Tùy chọn: Khởi động lại hiệu ứng nhấp nhô
