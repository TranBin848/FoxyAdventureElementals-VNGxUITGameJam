extends Panel
class_name SkillInfoPanelUltimate

signal error_occurred(message: String)

@onready var title_label: Label = $Title
@onready var level_label: Label = $Level
@onready var stat_label: RichTextLabel = $Stat
@onready var stack_label: Label = $Stack
@onready var close_button: Button = $CloseButton

var current_button: Node 
var current_skill_name: String = ""

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
	stack_label.text = ""
	
	stat_label.text = get_stat_text(sk)
	
func get_stat_text(sk: Skill) -> String:
	return "[center][i][color=#a0a0a0]\n\nThe stars have not yet aligned...\nThis power remains dormant for now.[/color][/i][/center]"

func _on_close_button_pressed():
	print("Close button pressed")
	visible = false
