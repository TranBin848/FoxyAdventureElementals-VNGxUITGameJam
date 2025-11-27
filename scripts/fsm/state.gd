extends Node
class_name FSMState

## Base state class for Finite State Machine states

var fsm: FSM = null
var obj: BaseCharacter = null
var timer: float = 0.0

func _enter() -> void:
	pass

func _exit() -> void:
	pass

func _update( _delta ):
	pass

# Update timer and return true if timer is finished
func update_timer(delta: float) -> bool:
	if timer <= 0:
		return false
	timer -= delta
	if timer <= 0:
		return true
	return false


func change_state(new_state: FSMState) -> void:
	fsm.change_state(new_state)
