extends Panel
class_name SkillInfoPanel

const ERROR_DISPLAY_TIME: float = 2.0
const UNLOCK_COST = 5
const UPGRADE_COST = 10

signal error_occurred(message: String)

@onready var title_label: Label = $Title
@onready var level_label: Label = $Level
@onready var stat_label: RichTextLabel = $Stat
@onready var stack_label: Label = $Stack
@onready var upgrade_btn: Button = $UpgradeButton
@onready var upgrade_label: Label = $StackToUpgrade
@onready var unlock_btn: Button = $UnlockButton
@onready var unlock_label: Label = $StackToUnlock
@onready var equip_button: Button = $EquipButton
@onready var video_player: VideoStreamPlayer = $VideoStreamPlayer
@onready var close_button: Button = $CloseButton

# Changed type to 'Node' to accept both SkillButtonNode and UltimateSkillButton
var current_button: Node 
var current_skill_name: String = ""

func _ready() -> void:
	if SkillTreeManager:
		SkillTreeManager.skill_unlocked.connect(_on_skill_unlocked)
		SkillTreeManager.skill_leveled_up.connect(_on_skill_leveled_up)
		SkillTreeManager.skill_equipped.connect(_on_skill_equipped)
		SkillTreeManager.skill_unequipped.connect(_on_skill_unequipped)
		SkillTreeManager.stack_changed.connect(_on_stack_changed)
	
	if close_button:
		close_button.pressed.connect(_on_close_button_pressed)

# Changed argument type to 'Node' to prevent crashes with Ultimate buttons
func show_skill(btn: Node):
	# Check if node has 'skill' property
	if not "skill" in btn or btn.skill == null:
		push_error("SkillInfoPanel: Received button with no skill!")
		return
	
	var sk = btn.skill
	
	visible = true
	current_button = btn
	current_skill_name = sk.name
	
	print("Showing skill: %s" % sk.name)
	
	title_label.text = sk.name
	
	# Only show level/stack info if NOT ultimate (optional, but cleaner)
	if sk.get("type") == "ultimate":
		level_label.text = "Level: ???"
		stack_label.text = ""
	else:
		level_label.text = "Level: %d" % SkillTreeManager.get_level(sk.name)
		stack_label.text = "Stack: %d" % SkillTreeManager.get_stacks(sk.name)
	
	stat_label.text = get_stat_text(sk)
	
	_update_buttons()
	
	# Safe check for video_stream property
	if "video_stream" in btn and btn.video_stream:
		video_player.stream = btn.video_stream
		video_player.play()
	else:
		video_player.stream = null
		video_player.stop()

func get_stat_text(sk: Skill) -> String:
	var lines: Array[String] = []
	
	var color_map := {
		ElementsEnum.Elements.FIRE: "[color=#ff4a4a]",   
		ElementsEnum.Elements.WATER: "[color=#4aaaff]",  
		ElementsEnum.Elements.EARTH: "[color=#c29a5b]",  
		ElementsEnum.Elements.WOOD: "[color=#4caf50]",   
		ElementsEnum.Elements.METAL: "[color=#d0d0d0]",  
	}

	var elem_color := "[color=white]"
	if color_map.has(sk.elemental_type):
		elem_color = color_map[sk.elemental_type]

	var elem_name = ElementsEnum.Elements.keys()[sk.elemental_type]
	var elemental_type_text := "%s%s[/color]" % [elem_color, elem_name]
	lines.append("Stats:                          " + elemental_type_text)
	lines.append("Damage: %d" % sk.damage)
	lines.append("Cooldown: %.2f s" % sk.cooldown)
	lines.append("Mana: %d" % sk.mana)
	lines.append("Duration: %.2f s" % sk.duration)
	
	var type_map := {
		"single_shot": "Single Shot",
		"multi_shot": "Multi Shot", 
		"radial": "Radial Burst",
		"area": "Area Effect",
		"buff": "Self Buff"
	}
	var skill_type_text = type_map.get(sk.type, sk.type)
	lines.append("Skill Type: %s" % skill_type_text)
	
	return "\n\n".join(lines)

func _update_buttons():
	if current_button == null:
		return
	
	var skill_name = current_skill_name
	var is_unlocked = SkillTreeManager.is_unlocked(skill_name)
	var stack_count = SkillTreeManager.get_stacks(skill_name)
	var level = SkillTreeManager.get_level(skill_name)
	
	unlock_btn.disabled = is_unlocked
	unlock_btn.text = "UNLOCKED" if is_unlocked else "UNLOCK (%d)" % UNLOCK_COST
	
	upgrade_btn.disabled = not is_unlocked or level >= 3
	upgrade_btn.text = "MAX LEVEL" if level >= 3 else "UPGRADE (%d)" % UPGRADE_COST
	
	var index = SkillTreeManager.find_skill_slot(skill_name)
	equip_button.text = "UNEQUIP" if index != -1 else "EQUIP"
	equip_button.disabled = not is_unlocked and stack_count == 0

func _on_unlock_button_pressed() -> void:
	if current_skill_name == "":
		return
	
	if SkillTreeManager.unlock_skill(current_skill_name, UNLOCK_COST):
		error_occurred.emit("Unlocked %s!" % current_skill_name)
		_update_buttons()
	else:
		var current_stacks = SkillTreeManager.get_stacks(current_skill_name)
		error_occurred.emit("Need %d stacks (have %d)" % [UNLOCK_COST, current_stacks])

func _on_upgrade_button_pressed() -> void:
	if current_skill_name == "":
		return
	
	if SkillTreeManager.upgrade_skill(current_skill_name, UPGRADE_COST):
		var new_level = SkillTreeManager.get_level(current_skill_name)
		error_occurred.emit("Upgraded to Lv%d!" % new_level)
		_update_buttons()
	else:
		var current_stacks = SkillTreeManager.get_stacks(current_skill_name)
		error_occurred.emit("Need %d stacks (have %d)" % [UPGRADE_COST, current_stacks])

func _on_equip_button_pressed() -> void:
	if current_skill_name == "":
		return

	var skill_name = current_skill_name
	var index = SkillTreeManager.find_skill_slot(skill_name)

	if index != -1:
		if SkillTreeManager.unequip_skill(index):
			error_occurred.emit("Unequipped from slot %d" % (index + 1))
			_update_buttons()
		return

	if not SkillTreeManager.is_unlocked(skill_name) and SkillTreeManager.get_stacks(skill_name) == 0:
		error_occurred.emit("Skill not unlocked!")
		return
	
	var bar = SkillTreeManager.get_skillbar()
	for i in range(bar.size()):
		if bar[i] == null:
			if SkillTreeManager.equip_skill(i, skill_name):
				error_occurred.emit("Equipped to slot %d!" % (i + 1))
				_update_buttons()
			return
	
	error_occurred.emit("Skill bar is full!")

func _on_skill_unlocked(skill_name: String):
	if skill_name == current_skill_name:
		_update_buttons()

func _on_skill_leveled_up(skill_name: String, new_level: int):
	if skill_name == current_skill_name:
		level_label.text = "Level: %d" % new_level
		_update_buttons()

func _on_skill_equipped(_slot_index: int, skill_name: String):
	if skill_name == current_skill_name:
		_update_buttons()

func _on_skill_unequipped(_slot_index: int, skill_name: String):
	if skill_name == current_skill_name:
		_update_buttons()

func _on_stack_changed(skill_name: String, new_stack: int):
	if skill_name == current_skill_name:
		stack_label.text = "Stack: %d" % new_stack

func _on_close_button_pressed():
	print("Close button pressed")
	visible = false
