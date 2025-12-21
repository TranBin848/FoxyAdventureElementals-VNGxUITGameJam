class_name FlyLightningState
extends BlackEmperorState

@export var warning_scene: PackedScene
@export var lightning_scene: PackedScene

func enter():
	print("Check")
	var player = get_tree().current_scene.find_child("Player", true, false)
	if player == null:
		change_state(fsm.states.idle)
		return

	var pos = player.global_position

	var warning = warning_scene.instantiate()
	warning.global_position = pos
	get_tree().current_scene.add_child(warning)

	await get_tree().create_timer(1.0).timeout

	if obj.current_phase != obj.Phase.FLY:
		if is_instance_valid(warning):
			warning.queue_free()
		change_state(fsm.states.idle)
		return

	var lightning = lightning_scene.instantiate()
	lightning.global_position = pos
	get_tree().current_scene.add_child(lightning)

	change_state(fsm.states.idle)
