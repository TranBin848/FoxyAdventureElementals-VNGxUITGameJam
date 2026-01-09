extends HBoxContainer
class_name StatRow

# Signal to tell the Main UI that a button was clicked
signal stat_changed(stat_def: Resource, change: int) 

var _def: Resource 

@onready var icon_rect: TextureRect = $IconContainer/Icon
@onready var name_lbl: Label = $NameLabel
@onready var val_lbl: Label = $ValueLabel
@onready var btn_minus: TextureButton = $MinusButton
@onready var btn_plus: TextureButton = $PlusButton

func setup(stat_def: Resource, current_value: int) -> void:
	print("DEBUG: StatRow setup for %s with value %d" % [stat_def.type, current_value])
	_def = stat_def
	
	if _def.display_name and _def.display_name != "":
		name_lbl.text = _def.display_name
	else:
		name_lbl.text = _def.type
	
	if _def.icon:
		icon_rect.texture = _def.icon
	else:
		icon_rect.visible = false
		
	update_value_display(current_value)

func update_value_display(current_value: int) -> void:
	val_lbl.text = str(current_value)
	if _def.value_per_point > 0:
		var actual_value = current_value * _def.value_per_point
		val_lbl.text = "%d (%d)" % [current_value, actual_value]

func update_buttons(points_available: int, can_decrease: bool) -> void:
	# Debug 1: Check inputs
	print("DEBUG: update_buttons for %s | Coins Available: %d | Can Decrease: %s" % [_def.type, points_available, can_decrease])

	# Check if we've hit the max points for this stat
	var current_points = int(val_lbl.text.split(" ")[0]) if " " in val_lbl.text else int(val_lbl.text)
	var at_max = false
	
	if _def.max_points > 0:
		at_max = current_points >= _def.max_points
	
	# Debug 2: Check Max Logic
	if at_max: print("DEBUG: Stat %s is at MAX points (%d)" % [_def.type, _def.max_points])
	
	# Disable (+) logic
	var plus_blocked = (points_available < _def.cost_per_point) # Check cost specifically!
	btn_plus.disabled = plus_blocked or at_max
	
	# Debug 3: Final Decision
	if btn_plus.disabled:
		print("DEBUG: Plus Button DISABLED. Reason: %s" % ["At Max" if at_max else "No Coins"])
	
	# Disable (-) logic
	btn_minus.disabled = not can_decrease
	
	# Visual Opacity Fix
	btn_plus.modulate.a = 0.5 if btn_plus.disabled else 1.0
	btn_minus.modulate.a = 0.5 if btn_minus.disabled else 1.0

func _on_minus_button_pressed() -> void:
	print("DEBUG: Minus pressed for ", _def.type)
	stat_changed.emit(_def, -1)

func _on_plus_button_pressed() -> void:
	print("DEBUG: Plus pressed for ", _def.type)
	stat_changed.emit(_def, 1)
