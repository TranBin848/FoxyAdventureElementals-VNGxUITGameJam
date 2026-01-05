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
Bấm C để chém và bấm X để ném đi."
"""
# Configuration for the guides
# Format: "EVENT_KEY": { "title": "", "content": "", "video": "" }
var guide_data: Dictionary = {
	"COIN": {
		"title": "Gold Coin",
		"content": "Bạn vừa nhặt được đồng vàng. Nó có giá trị trao đổi mua bán, hãy thu thập càng nhiều càng tốt nhé.",
		"image": "res://assets/skills/icons_skill/48x48/skill_icons16.png" 
	},
	"KEY": {
		"title": "Treasure Key",
		"content": "Bạn vừa tìm được chìa khóa để mở rương kho báu, hãy truy tìm rương báu và mở chúng ra để nhận được nhiều của cải nhé.",
		"image": "res://assets/skills/icons_skill/48x48/skill_icons16.png" 
	},
	"KILL": {
		"title": "Enemy Slain",
		"content": "Enemies drop elemental skills. Pick them up to grow stronger!",
		"video": "res://assets/videos/tutorial_combat.ogv"
	},
	"WOOD_WAND": {
		"title": "Wooden Wand!",
		"content": wood_wand_guide,
		"video": "res://assets/videos/tutorial_weapon_swap.ogv"
	},
	"CUTLASS": {
		"title": "Cutlass",
		"content": cutlass_guide,
		"image": "res://assets/skills/icons_skill/48x48/skill_icons16.png"
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

func _show_guide(key: String) -> void:
	var data = guide_data.get(key)
	if not data: return
	
	var popup = POPUP_SCENE.instantiate() as TutorialPopup
	
	# Add to the current scene (CanvasLayer is preferred if you have one, otherwise current_scene)
	GameManager.current_stage.find_child("GUI").add_child(popup)
	
	# Setup the data
	popup.setup(
		data.get("title", ""), 
		data.get("content", ""),
		data.get("video", ""), 
		data.get("image", "")
	)
