extends HBoxContainer

@export var player: Player = null

@onready var cur_icon: TextureRect = $PlayerIconPanelContainer/MarginContainer/TextureRect
@export var happy_icon: Texture2D
@export var neutral_icon: Texture2D
@export var sad_icon: Texture2D

@onready var health_label: Label = $PlayerHealthPanelContainer/MarginContainer/VBoxContainer/TextureProgressBar/Label

@onready var healthbar: TextureProgressBar = $PlayerHealthPanelContainer/MarginContainer/VBoxContainer/TextureProgressBar

var mood_timer: SceneTreeTimer
@export var hurt_icon: Texture2D


func _ready() -> void:
	player.health_changed.connect(_update)
	_update()

func _update() -> void:
	var hp_percent := float(player.health) / float(player.max_health) * 100.0

	# Update health bar + label
	healthbar.value = hp_percent
	health_label.text = str(player.health) + "/" + str(player.max_health)

	# Show hurt icon
	cur_icon.texture = hurt_icon

	# If a previous timer exists, stop it
	if mood_timer:
		mood_timer.timeout.disconnect(_on_mood_timer_timeout)  # safe disconnect
		mood_timer = null

	# Start a new timer
	mood_timer = get_tree().create_timer(0.5)
	mood_timer.timeout.connect(_on_mood_timer_timeout.bind(hp_percent))

func _on_mood_timer_timeout(hp_percent: float) -> void:
	_set_mood_icon(hp_percent)

func _set_mood_icon(hp_percent: float) -> void:
	if hp_percent < 25.0:
		cur_icon.texture = sad_icon
	elif hp_percent < 75.0:
		cur_icon.texture = neutral_icon
	else:
		cur_icon.texture = happy_icon
