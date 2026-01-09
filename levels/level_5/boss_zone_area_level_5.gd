extends Area2D
@onready var camera_2d: Camera2D = $Camera2D
@onready var collision: CollisionShape2D = $CollisionShape2D
@onready var sprite_2d: Sprite2D = $"../ParallaxBackground/ParallaxLayer/Sprite2D"

@export var boss: EnemyCharacter = null
@export var boss_music_id: String = ""
var previous_music_id
var player: Player = null
var triggered: bool = false

signal boss_killed
signal player_entered

func _ready() -> void:
	boss.boss_zone = self

func _physics_process(_delta: float) -> void:
	if triggered and player and is_instance_valid(player):
		# Prevent player from moving out of viewport edges
		if is_at_camera_edge(player):
			player.velocity.x = 0
			player.global_position.x -= 1 * player.direction

func _on_body_entered(body: Node2D) -> void:
	if triggered:
		return
	
	if body is Player:
		triggered = true
		player = body
		CameraTransition.transition_camera2D(camera_2d, 2)
		sprite_2d.texture = preload("res://assets/island/background/bgfinalboss.jpg")
		player_entered.emit()
		
	if boss:
		if boss.is_fighting:
			return
		boss.start_fight()
		previous_music_id = AudioManager.get_current_music_id()
		AudioManager.play_music(boss_music_id, 0, 2)

func _on_boss_dead() -> void:
	triggered = false
	if player:
		print("trigger")
		CameraTransition.transition_camera2D(player.camera_2d, 2)
	collision.disabled = true
	AudioManager.play_music("music_victory", 0, 2)
	AudioManager.play_next_music(previous_music_id, 0, 2)
	boss_killed.emit()

func is_at_camera_edge(source: Node2D, margin: float = 15.0) -> bool:
	var cam := get_viewport().get_camera_2d()
	if cam == null: return false
	var viewport := get_viewport()
	var screen_size := viewport.get_visible_rect().size
	var canvas_xform := viewport.get_canvas_transform().affine_inverse()
	var left_edge  = canvas_xform * Vector2(0, screen_size.y * 0.5)
	var right_edge = canvas_xform * Vector2(screen_size.x, screen_size.y * 0.5)
	var x := source.global_position.x
	return (x <= left_edge.x + margin and source.velocity.x < 0) or (x >= right_edge.x - margin and source.velocity.x > 0)
	
