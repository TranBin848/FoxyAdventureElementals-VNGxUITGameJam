extends CanvasLayer

func _input(event):
	if event.is_action_pressed("ui_skilltree"):
		var root = get_node("SkillTreeRoot")
		var skill_camera: Camera2D = root.get_node("SkillTreeButtonGroup/SubViewportContainer/SubViewport/SkillCamera2D")
		get_tree().paused = !get_tree().paused 
		if (visible == false):
			visible = true
			if not root:
				return
			_show_skill_tree_layers(root)
			# Khóa camera player để nó không giành lại quyền
			if GameManager.player:
				GameManager.player.camera_2d.enabled = false
			if skill_camera:
				#skill_camera.make_current()
				skill_camera.enabled = true
				print("📷 Đã chuyển sang camera UI SkillTree.")
			else:
				print("No Cam")

			print("🌳 Skill Tree opened.")
		else:	
			visible = false
			_hide_skill_tree_layers(root)
			if skill_camera:
				skill_camera.enabled = false
			# trả camera cho player
			if GameManager.player:
				if GameManager.player:
					GameManager.player.camera_2d.enabled = true
					GameManager.player.camera_2d.make_current()
					print("📷 Đã trả lại camera cho player.")

			print("🌳 Skill Tree closed.")
		

func _show_skill_tree_layers(root: Node):
	#root.visible = true
	for child in root.get_children():
		if child is CanvasLayer:
			child.visible = true

func _hide_skill_tree_layers(root: Node):
	#root.visible = false
	for child in root.get_children():
		if child is CanvasLayer:
			child.visible = false
