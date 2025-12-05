extends Panel
class_name SkillInfoPanel

@onready var title_label: Label = $Title
@onready var level_label: Label = $Level
@onready var stat_label: RichTextLabel = $Stat

func show_skill(btn: SkillButtonNode):
	var sk = btn.skill
	if sk == null:
		return
	
	visible = true
	title_label.text = sk.name
	level_label.text = "Level: %d" % btn.level
	stat_label.text = get_stat_text(sk)

func get_stat_text(sk: Skill) -> String:
	var lines: Array[String] = []
		
	# --- Element Color ---
	var color_map := {
		"Fire": "[color=#ff4a4a]",   # đỏ
		"Water": "[color=#4aaaff]",  # xanh nước
		"Earth": "[color=#c29a5b]",  # nâu đất
		"Wood": "[color=#4caf50]",   # xanh lá
		"Metal": "[color=#d0d0d0]",  # bạc
	}

	var elem_color := "[color=white]"
	if color_map.has(sk.element):
		elem_color = color_map[sk.element]

	# --- Header line ---
	var element_text := "%s%s[/color]" % [elem_color, sk.element]
	lines.append("Stats:                        " + element_text)

	# --- Các stats ---
	if sk.damage > 0:
		lines.append("Damage: %d" % sk.damage)

	if sk.cooldown > 0:
		lines.append("Cooldown: %.2f s" % sk.cooldown)

	if sk.mana > 0:
		lines.append("Mana: %d" % sk.mana)

	if sk.speed > 0:
		lines.append("Projectile Speed: %d" % sk.speed)

	if sk.duration > 0:
		lines.append("Duration: %.2f s" % sk.duration)

	if sk.type != "":
		lines.append("Skill Type: %s" % sk.type)

	# --- ghép dòng + spacing giả ---
	return "\n\n".join(lines)
