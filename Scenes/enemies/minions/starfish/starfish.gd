extends EnemyCharacter

var detected_player_icon: Sprite2D

func _ready() -> void:
	super._ready()
	fsm = FSM.new(self, $States, $States/Moving)
	if has_node("Direction/DetectedPlayerIcon"):
		detected_player_icon = $Direction/DetectedPlayerIcon
