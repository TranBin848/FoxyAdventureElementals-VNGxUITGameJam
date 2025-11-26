extends EnemyCharacter

func _ready() -> void:
	super._ready()
	fsm = FSM.new(self, $States, $States/Moving)
