# SkillInfoPanelUltimate.gd (Updated with ultimate logic from main panel)
extends Panel
class_name SkillInfoPanelUltimate

signal error_occurred(message: String)

@onready var title_label: Label = $Title
@onready var level_label: Label = $Level
@onready var stat_label: RichTextLabel = $Stat
@onready var close_button: Button = $CloseButton

var current_button: Node 
var current_skill_name: String = ""

# MOVED: Element-specific ultimate guides from main panel
var metal_ultimate_guide := """
Chúc mừng ngươi đã hé mắt nhìn vào cánh cửa đã bị phong ấn từ thuở cổ xưa của hệ Kim.
Nhưng với tầm nhìn hạn hẹp hiện tại, ngươi khó mà nhận ra thứ ẩn đằng sau khoảng không ấy.
Đó là một cõi nơi thép được sinh ra không ngừng, và không thứ gì quay trở lại nguyên vẹn …
Thôi, cứ thử bước gần thêm chút nữa, rồi ngươi sẽ hiểu vì sao chẳng ai trở ra.
"""

var fire_ultimate_guide := """
Chúc mừng ngươi đã chạm tay vào thần thuật bí ẩn của hệ Hỏa.
Nhưng với trái tim mong manh hiện tại, ngươi khó mà chịu nổi sự thiêu đốt đó.
Đây là ngọn lửa không bao giờ tắt …
Rồi một ngày — khi tro tàn biết chuyển mình — ngươi sẽ hiểu.
"""

var earth_ultimate_guide := """
Chúc mừng ngươi đã chạm tay vào tuyệt kỹ bất khuất của hệ Thổ.
Thế nhưng với đôi chân còn lung lay thế kia, ngươi chưa xứng đứng vững cùng sức mạnh này.
Đây là bí pháp gắn kết với đại địa cổ xưa …
Nhưng chắc ngươi chưa hiểu nổi đâu. Hãy học cách không bị đè bẹp trước đã.
"""

var wood_ultimate_guide := """
Chúc mừng ngươi đã chạm tay vào bí mật sinh trưởng của hệ Mộc.
Tiếc rằng hiểu biết của ngươi còn quá nông cạn để chạm đến cốt lõi của nó.
Đây là phép thuật gieo xuống một điều gì đó… nhỏ bé, nhưng dai dẳng hơn cả thời gian …
Rồi sẽ có ngày, khi thứ tưởng như đã biến mất lại khẽ lay động, ngươi sẽ hiểu vì sao
"""

var water_ultimate_guide := """
Chúc mừng ngươi đã chạm tay vào huyền thuật sắc lạnh của hệ Thủy.
Thế nhưng với ý chí còn chập chờn như làn sóng, ngươi chưa thể nắm bắt nó.
Đây là sức mạnh tưởng chừng mong manh — nhưng chưa bao giờ bị ngăn cản …
Rồi đến lúc, trong sự tĩnh lặng tuyệt đối, ngươi sẽ hiểu nó thực sự đi tới đâu.
"""

func _ready() -> void:
	if close_button:
		close_button.pressed.connect(_on_close_button_pressed)

func show_skill(btn: Node):
	if not "skill" in btn or btn.skill == null:
		push_error("SkillInfoPanelUltimate: Received button with no skill!")
		return
	
	var sk = btn.skill
	
	visible = true
	current_button = btn
	current_skill_name = sk.name
	
	print("Showing ultimate skill: %s" % sk.name)
	
	title_label.text = sk.name
	level_label.text = "Level: ???" 
	
	stat_label.text = get_stat_text(sk)

# MOVED: Complete ultimate description logic from main panel
func get_stat_text(sk: Skill) -> String:
	var result := ""
	if SkillTreeManager.is_unlocked(sk.name):
		match sk.elemental_type:
			ElementsEnum.Elements.FIRE:
				result = "[center][i][color=#a0a0a0]%s[/color][/i][/center]" % fire_ultimate_guide
			ElementsEnum.Elements.WOOD:
				result = "[center][i][color=#a0a0a0]%s[/color][/i][/center]" % wood_ultimate_guide
			ElementsEnum.Elements.METAL:
				result = "[center][i][color=#a0a0a0]%s[/color][/i][/center]" % metal_ultimate_guide
			ElementsEnum.Elements.WATER:
				result = "[center][i][color=#a0a0a0]%s[/color][/i][/center]" % water_ultimate_guide
			ElementsEnum.Elements.EARTH:
				result = "[center][i][color=#a0a0a0]%s[/color][/i][/center]" % earth_ultimate_guide
	else:
		result = "[center][i][color=#a0a0a0]\n\nBánh răng số phận vẫn đang chuyển mình\nCuộc hành trình của bạn vẫn chưa đến hồi kết...[/color][/i][/center]"
	return result

func _on_close_button_pressed():
	print("Close button pressed")
	visible = false
