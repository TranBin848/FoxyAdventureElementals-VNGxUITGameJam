extends AmbienceArea2D
@onready var camera_2d: Camera2D = $Camera2D
@onready var collision: CollisionShape2D = $CollisionShape2D
@export var boss: KingCrab = null #make sure boss zone alway have a boss
var player: Player = null

func _ready() -> void:
	boss.boss_zone = self

func _on_boss_dead() -> void:
	if player:
		CameraTransition.transition_camera2D(player.camera_2d, 2)
		player.camera_2d
	collision.disabled = true
	AudioManager.play_music("music_victory")
	AudioManager.play_next_music(previous_music_id)

func _on_body_entered(body: Node2D) -> void:
	if body is Player:
		player = body
		CameraTransition.transition_camera2D(camera_2d, 2)
	if boss:
		if boss.is_fighting:
			return
		boss.start_fight()
		previous_music_id = AudioManager.get_current_music_id()
		AudioManager.play_music(ambience_music_id)
	#boss.fsm.chan
