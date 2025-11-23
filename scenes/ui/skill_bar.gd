extends HBoxContainer

var slots: Array
var skills: Array = [WaterBall, WaterSpike, FireExplosion, WoodShot]

func _ready() -> void:
	slots = get_children()
	var player = get_tree().get_first_node_in_group("player")
	for i in get_child_count():
		slots[i].change_key = str(i + 1)
		if i <= skills.size() - 1:
			slots[i].skill = skills[i].new()
			slots[i].skill.apply_to_button(slots[i])
	if player:
		# Lắng nghe tín hiệu nhặt Skill từ Player
		player.skill_collected.connect(_on_skill_collected)

func _on_skill_collected(skill_resource_class: Script):
	for slot in slots:
		if slot.skill == null:
			# 1. Gán Skill vào slot trống
			slot.skill = skill_resource_class.new()
			
			# 2. ✅ CẬP NHẬT THUỘC TÍNH COOLDOWN VÀ TEXTURE
			slot.skill.apply_to_button(slot) 
			
			# 3. ✅ FIX: RESET TRẠNG THÁI NÚT BẤM (Nếu nó bị disabled)
			slot.disabled = false 
			slot.cooldown.value = 0
			slot.time_label.text = ""
			slot.set_process(false) # Dừng _process nếu đang chạy (như sau khi cooldown kết thúc)
			
			print("✅ New skill '%s' added to slot!" % slot.skill.name)
			return
	
	print("⚠️ Không có slot trống để chứa Skill mới!")
