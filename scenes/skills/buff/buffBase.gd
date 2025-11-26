# res://skills/buffs/BuffBase.gd
extends Area2D
class_name BuffBase

var elemental_type: int = 0
var caster: Node2D = null # ⬅️ Biến để lưu trữ tham chiếu đến Player
@export var y_offset: float = -10.0 # ⬅️ Độ cao dịch chuyển (âm để đi lên)
@export var x_offset: float = -5.0 # ⬅️ Độ cao dịch chuyển (âm để đi lên)
func setup(skill: Skill, caster_node: Node2D) -> void: # ⬅️ Nhận Player làm tham số
	elemental_type = skill.elemental_type
	caster = caster_node # Gán tham chiếu Player
	
	# Play animation if có AnimatedSprite2D
	if has_node("AnimatedSprite2D"):
		$AnimatedSprite2D.play(skill.animation_name)
	
	# NOTE: Node này sẽ được hủy bởi Player sau khi duration kết thúc.


func _physics_process(delta: float) -> void:
	# 🎯 FIX: Gán vị trí của Buff bằng vị trí của Player mỗi frame
	if is_instance_valid(caster):
		var offset_vector = Vector2(caster.direction * x_offset, y_offset)
		# Đảm bảo Buff luôn ở vị trí của Player
		global_position = caster.global_position + offset_vector
	else:
		# Tự hủy nếu Player đã bị hủy (để tránh lỗi)
		queue_free()

# ❌ XÓA CÁC HÀM KHÔNG CẦN THIẾT (Vì Buff không tự bay/hủy khi ra khỏi màn hình)
# func _move(delta: float) -> void: ...
# func _on_visible_on_screen_notifier_2d_screen_exited() -> void: ...
	
func play(animation_name: String):
	if has_node("AnimatedSprite2D"):
		$AnimatedSprite2D.play(animation_name)
	
func change_position(offset_y: float) -> void:
	if has_node("AnimatedSprite2D"):
		$AnimatedSprite2D.position.y += offset_y
