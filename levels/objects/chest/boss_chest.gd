extends RigidBody2D
class_name BossChest

const wand_pickup_scene: PackedScene = preload("res://scenes/wand/wand_pickup.tscn")

# 1. New Export to select level in Editor
# 0 = Normal, 1 = Sorrow, 2 = Soul (Matches Player Enum)
@export_enum("Normal", "Sorrow", "Soul") var drop_wand_level: int = 1 

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var interactive_area: InteractiveArea2D = $InteractiveArea2D 

var is_opened: bool = false

func _ready():
	animated_sprite.play("close")
	interactive_area.interacted.connect(attempt_open_chest)

func attempt_open_chest():
	if is_opened: return
	
	open_chest()

func open_chest():
	if is_opened: return
	is_opened = true
	
	animated_sprite.play("open")
	if AudioManager: AudioManager.play_sound("chest_open")
	
	interactive_area.queue_free() 
	
	await animated_sprite.animation_finished
	spawn_wand()

func spawn_wand():
	if wand_pickup_scene == null: return

	var wand_instance = wand_pickup_scene.instantiate()
	get_tree().current_scene.add_child(wand_instance)
	wand_instance.global_position = global_position
	
	# 2. Pass the selected level to the wand
	if "wand_level" in wand_instance:
		wand_instance.set_wand_level(drop_wand_level)
