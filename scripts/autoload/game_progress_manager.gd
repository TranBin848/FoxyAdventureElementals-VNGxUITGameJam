extends Node

# Load your popup scene here
const POPUP_SCENE = preload("res://scenes/ui/popup/guide_popup.tscn")

# State Flags
var first_coin_collected: bool = false
var first_key_collected: bool = false
var first_enemy_killed: bool = false
var first_cutlass_collected: bool = false
var first_wood_wand_collected: bool = false
var fire_ultimate_collected: bool = false
var water_ultimate_collected: bool = false
var wood_ultimate_collected: bool = false
var metal_ultimate_collected: bool = false
var earth_ultimate_collected: bool = false
var first_time_open_skill_tree: bool = false


var cutlass_media_path = "res://scenes/ui/popup/guide_content/cutlass_guide.ogv"
var coin_media_path = "res://scenes/ui/popup/guide_content/coin_guide.ogv"
var key_media_path = "res://scenes/ui/popup/guide_content/key_guide.ogv"
var skill_tree_media_path = "res://scenes/ui/popup/guide_content/skill_tree_guide.png"
var wand_media_path = "res://scenes/ui/popup/guide_content/wand_guide.ogv"

var metal_ultimate_media_path = "res://assets/skills/icon element/Metal_v2.png"
var wood_ultimate_media_path = "res://assets/skills/icon element/Wood_v2.png"
var water_ultimate_media_path = "res://assets/skills/icon element/Water_v2.png"
var fire_ultimate_media_path = "res://assets/skills/icon element/Fire_v2.png"
var earth_ultimate_media_path = "res://assets/skills/icon element/Earth_v2.png"


var wood_wand_guide := """
Bạn vừa nhận được trượng gỗ. Viên đá trên cây trượng sẽ giúp bạn đọc được ngôn ngữ phép thuật. Từ đó học được cách sử dụng phép.
Hãy ấn một số từ 1-5 để chọn một phép trên thanh skill bar.Sau đó bấm C để sử dụng phép.
Nếu phép bạn chọn hiện chỉ ở dạng cuộn giấy phép. Bạn sẽ mất đi 1 cuộn giấy phép đó.
Nếu bạn có nhiều cuộn phép của 1 loại phép, bạn có thể học vĩnh viễn phép đó.
Ấn Tab để bật Skill Tree và học phép trong đó nhé.
"""

var cutlass_guide := """
Bạn vừa nhặt được một thanh Cutlass.
Thế giới ngoài kia có thể nguy hiểm lắm nên hãy cầm theo để phòng thân nhé.
Bấm C để chém và bấm X phóng đi.
"""

var skill_tree_guide := """
Chào mừng bạn đến với Skill Tree lần đầu tiên.
Bạn có thể chọn 1 phép và học nó nếu bạn có đủ số lượng cuộn phép.
Khi đã học, bạn có thể dùng phép đó mà không tốn cuộn phép.
Để nâng cấp 1 phép đã học nhằm tăng các chỉ số của nó, bạn phải thu thập thêm cuộn phép của phép đó.
Số lượng cuộn phép bạn thu thập được sẽ hiển thị ở góc trên bên phải mỗi ô phép.
Bấm vào 1 phép để xem mô tả chi tiết của nó.
"""

var metal_ultimate_guide := """
Chúc mừng ngươi đã hé mắt nhìn vào cánh cửa đã bị phong ấn từ thuở cổ xưa của hệ Kim.
Nhưng với tầm nhìn hạn hẹp hiện tại, ngươi khó mà nhận ra thứ ẩn đằng sau khoảng không ấy.
Đó là một cõi nơi thép được sinh ra không ngừng, và không thứ gì quay trở lại nguyên vẹn …
Thôi, cứ thử bước gần thêm chút nữa, rồi ngươi sẽ hiểu vì sao chẳng ai trở ra.
"""

var fire_ultimate_guide := """
Chúc mừng ngươi đã chạm tay vào thần thuật bí ẩn của hệ Hỏa.
Nhưng với trái tim mong manh hiện tại, ngươi khó mà chịu nổi sự thiêu đốt đó.
Đây là ngọn lửa không bao giờ tắt …
Rồi một ngày — khi tro tàn biết chuyển mình — ngươi sẽ hiểu.
"""

var earth_ultimate_guide := """
Chúc mừng ngươi đã chạm tay vào tuyệt kỹ bất khuất của hệ Thổ.
Thế nhưng với đôi chân còn lung lay thế kia, ngươi chưa xứng đứng vững cùng sức mạnh này.
Đây là bí pháp gắn kết với đại địa cổ xưa …
Nhưng chắc ngươi chưa hiểu nổi đâu. Hãy học cách không bị đè bẹp trước đã.
"""

var wood_ultimate_guide := """
Chúc mừng ngươi đã chạm tay vào bí mật sinh trưởng của hệ Mộc.
Tiếc rằng hiểu biết của ngươi còn quá nông cạn để chạm đến cốt lõi của nó.
Đây là phép thuật gieo xuống một điều gì đó… nhỏ bé, nhưng dai dẳng hơn cả thời gian …
Rồi sẽ có ngày, khi thứ tưởng như đã biến mất lại khẽ lay động, ngươi sẽ hiểu vì sao
"""

var water_ultimate_guide := """
Chúc mừng ngươi đã chạm tay vào huyền thuật sắc lạnh của hệ Thủy.
Thế nhưng với ý chí còn chập chờn như làn sóng, ngươi chưa thể nắm bắt nó.
Đây là sức mạnh tưởng chừng mong manh — nhưng chưa bao giờ bị ngăn cản …
Rồi đến lúc, trong sự tĩnh lặng tuyệt đối, ngươi sẽ hiểu nó thực sự đi tới đâu.
"""

# Configuration for the guides
# Format: "EVENT_KEY": { "title": "", "content": "", "video": "" }
var guide_data: Dictionary = {
	"COIN": {
		"title": "Gold Coin",
		"content": "Bạn vừa nhặt được đồng vàng. Nó có giá trị trao đổi mua bán, hãy thu thập càng nhiều càng tốt nhé.",
		"video": coin_media_path 
	},
	"KEY": {
		"title": "Treasure Key",
		"content": "Bạn vừa tìm được chìa khóa để mở rương kho báu, hãy truy tìm rương báu và mở chúng ra để nhận được nhiều của cải nhé.",
		"video": key_media_path
	},
	"KILL": {
		"title": "Enemy Slain",
		"content": "Enemies drop elemental skills. Pick them up to grow stronger.",
		"video": "res://assets/videos/tutorial_combat.ogv"
	},
	"WOOD_WAND": {
		"title": "Wooden Wand",
		"content": wood_wand_guide,
		"video": wand_media_path
	},
	"CUTLASS": {
		"title": "Cutlass",
		"content": cutlass_guide,
		"video": cutlass_media_path
	},
	"SKILL_TREE": {
		"title": "Skill Tree",
		"content": skill_tree_guide,
		"image": skill_tree_media_path
	},
	"METAL_ULTIMATE": {
		"title": "Metal Ultimate",
		"content": metal_ultimate_guide,
		"image": metal_ultimate_media_path
	},
		"FIRE_ULTIMATE": {
		"title": "Fire Ultimate",
		"content": fire_ultimate_guide,
		"image": fire_ultimate_media_path
	},
	"EARTH_ULTIMATE": {
		"title": "Earth Ultimate",
		"content": earth_ultimate_guide,
		"image": earth_ultimate_media_path
	},
	"WOOD_ULTIMATE": {
		"title": "Wood Ultimate",
		"content": wood_ultimate_guide,
		"image": wood_ultimate_media_path
	},
	"WATER_ULTIMATE": {
		"title": "Water Ultimate",
		"content": water_ultimate_guide,
		"image": water_ultimate_media_path
	}
}

func trigger_event(event_type: String) -> void:
	match event_type:
		"COIN":
			if first_coin_collected: return
			first_coin_collected = true
			_show_guide("COIN")
			
		"KEY":
			if first_key_collected: return
			first_key_collected = true
			_show_guide("KEY")
			
		"KILL":
			if first_enemy_killed: return
			first_enemy_killed = true
			_show_guide("KILL")
			
		"CUTLASS":
			if first_cutlass_collected: return
			first_cutlass_collected = true
			_show_guide("CUTLASS")
			
		"WOOD_WAND":
			if first_wood_wand_collected: return
			first_wood_wand_collected = true
			_show_guide("WOOD_WAND")
			
		"SKILL_TREE":
			if first_time_open_skill_tree: return
			first_time_open_skill_tree = true
			_show_guide("SKILL_TREE")
			
		"METAL_ULTIMATE":
			if metal_ultimate_collected: return
			metal_ultimate_collected = true
			_show_guide("METAL_ULTIMATE")
			
		"FIRE_ULTIMATE":
			if fire_ultimate_collected: return
			fire_ultimate_collected = true
			_show_guide("FIRE_ULTIMATE")
			
		"EARTH_ULTIMATE":
			if earth_ultimate_collected: return
			earth_ultimate_collected = true
			_show_guide("EARTH_ULTIMATE")
			
		"WOOD_ULTIMATE":
			if wood_ultimate_collected: return
			wood_ultimate_collected = true
			_show_guide("WOOD_ULTIMATE")
			
		"WATER_ULTIMATE":
			if water_ultimate_collected: return
			water_ultimate_collected = true
			_show_guide("WATER_ULTIMATE")

func _show_guide(key: String) -> void:
	var data = guide_data.get(key)
	if not data: return
	
	var popup = POPUP_SCENE.instantiate() as TutorialPopup
	
	# Add to the current scene (CanvasLayer is preferred if you have one, otherwise current_scene)
	if key == "SKILL_TREE":
		GameManager.current_stage.find_child("SkillTreeUI").add_child(popup)
	else:
		GameManager.current_stage.find_child("GUI").add_child(popup)
	
	# Setup the data
	popup.setup(
		data.get("title", ""), 
		data.get("content", ""),
		data.get("video", ""), 
		data.get("image", "")
	)
	
#region Save & Load Logic
func get_save_data() -> Dictionary:
	return {
		"first_coin_collected": first_coin_collected,
		"first_key_collected": first_key_collected,
		"first_enemy_killed": first_enemy_killed,
		"first_cutlass_collected": first_cutlass_collected,
		"first_wood_wand_collected": first_wood_wand_collected,
		"fire_ultimate_collected": fire_ultimate_collected,
		"water_ultimate_collected": water_ultimate_collected,
		"wood_ultimate_collected": wood_ultimate_collected,
		"metal_ultimate_collected": metal_ultimate_collected,
		"earth_ultimate_collected": earth_ultimate_collected,
		"first_time_open_skill_tree": first_time_open_skill_tree
	}

func load_save_data(data: Dictionary) -> void:
	if data.is_empty(): return
	
	first_coin_collected = data.get("first_coin_collected", false)
	first_key_collected = data.get("first_key_collected", false)
	first_enemy_killed = data.get("first_enemy_killed", false)
	first_cutlass_collected = data.get("first_cutlass_collected", false)
	first_wood_wand_collected = data.get("first_wood_wand_collected", false)
	fire_ultimate_collected = data.get("fire_ultimate_collected", false)
	water_ultimate_collected = data.get("water_ultimate_collected", false)
	wood_ultimate_collected = data.get("wood_ultimate_collected", false)
	metal_ultimate_collected = data.get("metal_ultimate_collected", false)
	earth_ultimate_collected = data.get("earth_ultimate_collected", false)
	first_time_open_skill_tree = data.get("first_time_open_skill_tree", false)
#endregion
