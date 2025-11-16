extends EnemyCharacter

func _ready() -> void:
	super._ready()
	fsm = FSM.new(self, $States, $States/Walk)

func reached_boss_screen_edge() -> bool:
	return true
