extends Area2D
@onready var camera_2d: Camera2D = $Camera2D
@onready var collision: CollisionShape2D = $CollisionShape2D
@export var boss: KingCrab = null #make sure boss zone alway have a boss
@export var boss_bgm: AudioStream = null
@export var normal_bgm: AudioStream = BackgroundMusic.stream
var player: Player = null

func _ready() -> void:
	boss.boss_zone = self

func _on_boss_dead() -> void:
	if player:
		CameraTransition.transition_camera2D(player.camera_2d, 2)
		player.camera_2d
	collision.disabled = true
	BackgroundMusic.stream = normal_bgm
	BackgroundMusic.play

func _on_body_entered(body: Node2D) -> void:
	if body is Player:
		player = body
		CameraTransition.transition_camera2D(camera_2d, 2)
	if boss:
		boss.start_fight()
		BackgroundMusic.stream = boss_bgm
		BackgroundMusic.play()
	#boss.fsm.chan
