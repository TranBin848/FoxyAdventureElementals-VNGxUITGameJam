extends TextureButton

const ERROR_DISPLAY_TIME: float = 1.0 

@onready var cooldown: TextureProgressBar = $Cooldown
@onready var key_label: Label = $Key
@onready var time_label: Label = $Time
@onready var timer: Timer = $Timer
@onready var alert_label: Label = get_tree().root.find_child("Label", true, false)

var skill: Skill = null
var _change_key: String = ""

var change_key: String:
	set(value):
		_change_key = value
		key_label.text = value
		var shortcut_obj = Shortcut.new()
		var input_key = InputEventKey.new()
		input_key.keycode = value.unicode_at(0)
		shortcut_obj.events = [input_key]
		self.shortcut = shortcut_obj

func _ready() -> void:
	change_key = "1"
	if skill:
		cooldown.max_value = skill.cooldown
		timer.wait_time = skill.cooldown
	else:
		cooldown.max_value = timer.wait_time
	set_process(false)

func _process(_delta: float) -> void:
	if timer.is_stopped():
		return
	time_label.text = "%.1f" % timer.time_left
	cooldown.value = timer.wait_time - timer.time_left

func _on_pressed() -> void:
	if disabled or skill == null:
		return

	var player = get_tree().get_first_node_in_group("player")
	if player:
		player.cast_spell(skill)
	else:
		printerr("Không tìm thấy Player trong group 'player'")
	
	var cast_successful: bool = player.cast_spell(skill)
	# 2. CHỈ KÍCH HOẠT COOLDOWN nếu thi triển THÀNH CÔNG
	if cast_successful:
		timer.start()
		disabled = true
		set_process(true)
	else:
		_show_error_text("Enemy Out of Range.")
	
func _on_timer_timeout() -> void:
	disabled = false
	time_label.text = ""
	cooldown.value = 0
	set_process(false)

func _show_error_text(message: String) -> void:
	if alert_label == null:
		printerr("Label thông báo chưa được tìm thấy trong Scene Tree!")
		return
	
	alert_label.text = message
	alert_label.visible = true
	alert_label.modulate = Color(1, 1, 1, 1) # Đảm bảo không trong suốt ban đầu
	
	# Khởi tạo Tween để làm hiệu ứng Fade Out
	var tween = create_tween()
	
	# Chờ một chút
	tween.tween_interval(ERROR_DISPLAY_TIME)
	
	# Fade Out và ẩn Label
	tween.tween_property(alert_label, "modulate", Color(1, 1, 1, 0), 0.3)
	
	# Sau khi fade xong, đảm bảo label.visible = false
	tween.tween_callback(Callable(alert_label, "set_visible").bind(false))
