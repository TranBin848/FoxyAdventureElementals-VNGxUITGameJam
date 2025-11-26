class_name FSM
extends Node

## Finite State Machine that manages character states and transitions

var debug: bool = false
var states: Dictionary = {}
var current_state: FSMState = null

var previous_state: FSMState = null
var default_state: FSMState = null
var obj: Node = null

var _next_state: FSMState = null

func _init(target_obj: Node, states_parent_node: Node, initial_state: FSMState, debug_mode: bool = false) -> void:
	self.obj = target_obj
	self.debug = debug_mode
	_set_states_parent_node(states_parent_node)
	_next_state = initial_state
	default_state = initial_state


func _set_states_parent_node(parent_node: Node) -> void:
	if debug:
		print("Found ", parent_node.get_child_count(), " states")
	if parent_node.get_child_count() == 0:
		return
	var state_nodes: Array = parent_node.get_children()
	for state_node in state_nodes:
		if debug:
			print("adding state: ", state_node.name)
		var normalized_name: String = state_node.name.to_lower()
		states[normalized_name] = state_node
		state_node.fsm = self
		state_node.obj = self.obj


func change_state(new_state: FSMState) -> void:
	if new_state == null:
		if debug:
			print("Warning: Trying to change to null state")
		return

	if new_state == current_state:
		if debug:
			print("Warning: Trying to change to same state")
		return

	if not states.has(new_state.name.to_lower()):
		if debug:
			print("Warning: State ", new_state.name, " not found in states")
		return
	_next_state = new_state


func _update(delta: float) -> void:
	if _next_state != current_state:
		if current_state != null:
			if debug:
				print(obj.name, ": changing from state ", current_state.name, " to ", _next_state.name)
			current_state._exit()
		elif debug:
			print(obj.name, ": starting with state ", _next_state.name)
		previous_state = current_state
		current_state = _next_state
		current_state._enter()
	# Run state
	current_state._update(delta)
