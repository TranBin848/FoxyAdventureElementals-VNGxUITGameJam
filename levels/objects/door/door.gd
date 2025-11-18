extends Node2D

@export_file("*.tscn") var target_stage: String = ""
@export var target_door: String = "Door"

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var fade_layer: CanvasLayer = get_tree().get_first_node_in_group("FadeLayer")

var is_busy := false

func _on_interactive_area_2d_interacted() -> void:
	if is_busy:
		return
	is_busy = true
	await open_door_and_transition()
	is_busy = false


func open_door_and_transition() -> void:
	if sprite.sprite_frames.has_animation("opening"):
		sprite.play("opening")
		await sprite.animation_finished

	# 🔹 2. Fade màn hình tối dần
	if fade_layer:
		await fade_layer.fade_out()

	# 🔹 3. Xử lý dịch chuyển hoặc đổi scene
	var stage_path_real = ProjectSettings.globalize_path(target_stage)
	stage_path_real = ProjectSettings.localize_path(stage_path_real)
	print(GameManager.current_stage.scene_file_path)
	print(stage_path_real)
	if GameManager.current_stage.scene_file_path == stage_path_real:
		# Nếu cùng stage → chỉ di chuyển player
		var door_node = GameManager.current_stage.find_child(target_door)
		if door_node and GameManager.player:
			GameManager.player.global_position = door_node.global_position
	else:
		GameManager.change_stage(target_stage, target_door)

	# 🔹 4. Fade sáng lại
	if fade_layer:
		await fade_layer.fade_in()

	# 🔹 5. Đóng cửa lại (nếu có animation “close”)
	if sprite.sprite_frames.has_animation("closing"):
		sprite.play("closing")
