extends HBoxContainer

var slots: Array
var skills: Array = [FireShot, WaterBall, Tornado, FireExplosion]

func _ready() -> void:
	slots = get_children()
	for i in get_child_count():
		slots[i].change_key = str(i + 1)
		if i <= skills.size() - 1:
			slots[i].skill = skills[i].new()
			slots[i].skill.apply_to_button(slots[i])
