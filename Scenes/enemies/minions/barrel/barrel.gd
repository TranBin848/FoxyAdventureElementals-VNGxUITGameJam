extends EnemyCharacter

func _ready() -> void:
	fsm = FSM.new(self, $States, $States/Idle)
	super._ready()
