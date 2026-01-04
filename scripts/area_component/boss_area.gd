extends Area2D
@onready var camera_2d: Camera2D = $Camera2D
@onready var collision: CollisionShape2D = $CollisionShape2D
@export var boss: EnemyCharacter = null #make sure boss zone alway have a boss
@export var boss_music_id: String = ""
var previous_music_id
var player: Player = null
var triggered: bool = false

func _ready() -> void:
	boss.boss_zone = self

func _on_boss_dead() -> void:
	
	if player:
		print("trigger")
		CameraTransition.transition_camera2D(player.camera_2d, 2)
		#player.camera_2d
	collision.disabled = true
	AudioManager.play_music("music_victory", 0, 2)
	AudioManager.play_next_music(previous_music_id, 0, 2)

func _on_body_entered(body: Node2D) -> void:
	if triggered:
		return
	
	if body is Player:
		triggered = true
		player = body
		CameraTransition.transition_camera2D(camera_2d, 2)
	if boss:
		if boss.is_fighting:
			return
		boss.start_fight()
		previous_music_id = AudioManager.get_current_music_id()
		AudioManager.play_music(boss_music_id, 0, 2)
	#boss.fsm.chan
