extends Control

@onready var timer: Timer = $Timer

const QTE_path = "res://scenes/ui/popup/quick_time_event.tscn"

var keyList = [
	{"keyString": "Q", "keyCode": KEY_Q},
	{"keyString": "E", "keyCode": KEY_E},
	{"keyString": "E", "keyCode": KEY_E},
	{"keyString": "Q", "keyCode": KEY_Q},
	{"keyString": "Q", "keyCode": KEY_Q},
	{"keyString": "E", "keyCode": KEY_E},
	{"keyString": "E", "keyCode": KEY_E},
	{"keyString": "Q", "keyCode": KEY_Q},
]

var count = 0
var keyPressedList = []

	
func _on_timer_timeout() -> void:
	if count == keyList.size():
		timer.stop()
		return

	var keyNode = load(QTE_path).instantiate()
	keyNode.finished.connect(_on_key_finished)
	keyNode.keyCode = keyList[count].keyCode
	keyNode.keyString = keyList[count].keyString

	add_child(keyNode)
	count += 1

func _on_key_finished(keySuccess):
	keyPressedList.append(keySuccess)
