extends AnimationPlayer

signal cutscene2_started
signal cutscene3_started
signal cutscene4_started
signal all_cutscenes_finished

var boss: BlackEmperor = null
var player: Player = null
var player_pos_cutscene1: Node2D = null
var boss_pos_cutscene1: Node2D = null

func _ready() -> void:
	# Thêm vào group để các state có thể tìm thấy
	add_to_group("animated_bg")
	
	# Tìm boss trong scene
	await get_tree().process_frame
	boss = get_tree().get_first_node_in_group("enemies") as BlackEmperor
	
	# Tìm player theo tên node
	player = get_tree().root.find_child("Player", true, false) as Player
	
	# Tìm các position nodes
	player_pos_cutscene1 = get_node_or_null("PLayerPosCutscene1")
	boss_pos_cutscene1 = get_node_or_null("BossPosCutscene1")
	
	if boss:
		boss.phase_transition_started.connect(_on_phase_transition_started)
		print("AnimatedBg connected to boss signal")
	else:
		print("AnimatedBg: Boss not found!")
	
	if not player:
		print("AnimatedBg: Player not found!")
	
	if not player_pos_cutscene1 or not boss_pos_cutscene1:
		print("AnimatedBg: Position nodes not found!")

func _on_phase_transition_started() -> void:
	print("AnimatedBg: Starting cutscene sequence")
	await play_cutscene_sequence()

func play_cutscene_sequence() -> void:
	# Cutscene1 state sẽ tự xử lý mọi thứ và trigger animation cutscene1
	# AnimatedBg chỉ chờ, KHÔNG tự động play các animation tiếp theo
	# Mỗi cutscene state sẽ tự quyết định khi nào chuyển state tiếp theo
	
	# Chờ tất cả cutscenes hoàn thành (signal từ cutscene4)
	await all_cutscenes_finished
	
	print("AnimatedBg: All cutscenes finished")
	
	# === CUTSCENE CLEANUP ===
	# Re-enable player input (đã được xử lý trong cutscene states)
	if player:
		player.set_physics_process(true)
	
	# Sau khi cutscene xong, boss tự mất 1/3 máu
	if boss:
		var damage_to_deal = int(boss.max_health * 0.3334)  # Mất thêm 33.34% máu
		boss.take_damage(damage_to_deal)
		print("Boss took ", damage_to_deal, " damage from cutscene")

func play_sound(sound_name: String) ->void:
	AudioManager.play_sound(sound_name)
