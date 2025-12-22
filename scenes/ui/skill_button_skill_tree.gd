extends TextureButton
class_name SkillButtonNode

@onready var panel: Panel = $Panel
@onready var level_label: Label = $MarginContainer/LevelLabel
@onready var stack_label: Label = $MarginContainer/StackLabel
@onready var line_2d: Line2D = $Line2D

@export var skill: Skill
@export var max_level: int = 3 # Giới hạn level hiển thị
@export var video_stream: VideoStream = null

var children: Array[SkillButtonNode] = []

# Line colors
const NORMAL_COLOR: Color = Color(0.5, 0.5, 0.5, 0.7)     # Xám (Chưa mở)
const UNLOCKED_COLOR: Color = Color(1, 1, 0.3, 1.0)       # Vàng (Đã mở)
const PARENT_COLOR: Color = Color(0.8, 0.8, 0.2, 1.0)     # Vàng đậm (Đường dẫn cha)

signal skill_selected(skill)

func _ready() -> void:
	# --- Logic vẽ dây nối với cha ---
	if get_parent() is SkillButtonNode:
		var parent_btn: SkillButtonNode = get_parent()
		parent_btn.children.append(self)
		
		# Sửa lỗi vẽ Line2D: Tính toán tọa độ tương đối thay vì global_position thô
		# Điểm 1: Tâm của nút hiện tại (Local)
		line_2d.add_point(size / 2) 
		
		# Điểm 2: Tâm của nút cha (Tính tương đối từ nút con)
		var relative_pos = parent_btn.global_position - global_position
		line_2d.add_point(relative_pos + parent_btn.size / 2)
		
		line_2d.default_color = NORMAL_COLOR
		
	# --- Kết nối với SkillTreeManager (Thay vì SkillStackManager) ---
	SkillTreeManager.stack_changed.connect(_on_stack_changed)     # Runtime Stacks
	SkillTreeManager.skill_leveled_up.connect(_on_level_changed)  # Permanent Level
	SkillTreeManager.skill_unlocked.connect(_on_skill_unlocked)   # Permanent Unlock
	
	_update_line_color()

var level : int = 0:
	set(value):
		level = value
		level_label.text = str(level) + "/" + str(max_level)

var stack: int = 0
var unlocked: bool = false

func _on_pressed() -> void:
	emit_signal("skill_selected", self)

# Hàm khởi tạo dữ liệu khi mở bảng Skill
func set_skill():
	if skill == null:
		return

	if skill.texture_path:
		texture_normal = load(skill.texture_path)
	
	# 1. Lấy dữ liệu Bền vững (Level & Unlock)
	level = SkillTreeManager.get_level(skill.name)
	unlocked = SkillTreeManager.get_unlocked(skill.name)
	
	# 2. Lấy dữ liệu Tạm thời (Stack - Runtime only)
	stack = SkillTreeManager.get_skill_stack(skill.name)
	stack_label.text = str(stack)
	
	# Cập nhật trạng thái hiển thị
	if unlocked:
		disabled = false
		panel.show_behind_parent = true 
	else:
		panel.show_behind_parent = false
		
	tooltip_text = skill.name
	
	_update_line_color()
	
	# Kiểm tra logic hiển thị đường nối tới con
	if unlocked:
		_unlock_children_visuals()

# --- CÁC HÀM UPDATE VISUAL ---

func _update_line_color():
	if unlocked:
		line_2d.default_color = UNLOCKED_COLOR
		line_2d.width = 4
	else:
		line_2d.default_color = NORMAL_COLOR
		line_2d.width = 2

# Signal: Skill được mở khóa (Mua bằng tiền hoặc đạt điều kiện)
func _on_skill_unlocked(skill_name: String):
	if skill == null or skill_name != skill.name:
		return
	
	unlocked = true
	disabled = false
	panel.show_behind_parent = true
	_update_line_color()
	_unlock_children_visuals()

# Signal: Stack thay đổi (Nhặt được trong game -> Cập nhật số, không save)
func _on_stack_changed(skill_name: String, new_stack: int):
	if skill == null or skill_name != skill.name:
		return

	stack = new_stack
	stack_label.text = str(stack)

# Signal: Level thay đổi
func _on_level_changed(skill_name: String, new_level: int):
	if skill == null or skill_name != skill.name:
		return

	level = new_level
	_update_line_color()

# Kích hoạt hiển thị đường dẫn tới các nút con
func _unlock_children_visuals():
	for child in children:
		# Logic: Nếu cha đã unlock, đường dây nối tới con sẽ sáng lên 
		# (hoặc bạn có thể đặt điều kiện level >= 3 mới sáng dây)
		child._highlight_line()

# Hàm con tự highlight dây của mình
func _highlight_line():
	line_2d.default_color = UNLOCKED_COLOR
	line_2d.width = 4
	
	# Đệ quy ngược: Highlight cả dây của cha để tạo hiệu ứng "dòng chảy" năng lượng
	if get_parent() is SkillButtonNode:
		get_parent()._highlight_parent_line()

func _highlight_parent_line():
	line_2d.default_color = PARENT_COLOR
	line_2d.width = 5
