extends HBoxContainer

@export var player: Player = null

@onready var cur_icon: TextureRect = $PlayerIconPanelContainer/MarginContainer/TextureRect
@export var happy_icon: Texture2D
@export var neutral_icon: Texture2D
@export var sad_icon: Texture2D
@export var hurt_icon: Texture2D

# Health UI
@onready var healthbar: TextureProgressBar = $PlayerBarsPanelContainer/MarginContainer/VBoxContainer/HealthProgressBar
@onready var health_label: Label = $PlayerBarsPanelContainer/MarginContainer/VBoxContainer/HealthProgressBar/Label

# Mana UI
@onready var mana_label: Label = $PlayerBarsPanelContainer/MarginContainer/VBoxContainer/ManaProgressBar/Label
@onready var manabar: TextureProgressBar = $PlayerBarsPanelContainer/MarginContainer/VBoxContainer/ManaProgressBar

var hurt_Timer: float = 0
var previous_health: int = 0

func _ready() -> void:
	call_deferred("_setup")


func _setup() -> void:
	if player == null:
		player = get_tree().get_first_node_in_group("player")
	
	if player == null:
		return
	
	previous_health = player.health
	player.health_changed.connect(_on_health_change)
	player.hurt.connect(_show_hurt_icon)
	player.mana_changed.connect(_update_mana)

	_on_health_change()
	_update_mana()


func _on_health_change() -> void:
	_update_health()
	_set_mood_icon()

# -----------------------------
# HEALTH UPDATE
# -----------------------------
func _update_health() -> void:
	var hp_percent := get_health_percentage()

	# update UI
	healthbar.value = hp_percent

	health_label.text = str(max(player.health,0)) + "/" + str(player.max_health)


func get_health_percentage() -> float:
	return float(player.health) / float(player.max_health) * 100.0

func _show_hurt_icon() -> void:
	cur_icon.texture = hurt_icon

	await get_tree().create_timer(0.5).timeout
	_set_mood_icon()

func _set_mood_icon() -> void:
	if cur_icon.texture == hurt_icon: return
	var hp_percent = get_health_percentage()
	if hp_percent < 25.0:
		cur_icon.texture = sad_icon
	elif hp_percent < 75.0:
		cur_icon.texture = neutral_icon
	else:
		cur_icon.texture = happy_icon


# -----------------------------
# MANA UPDATE
# -----------------------------
func _update_mana() -> void:
	var mana_percent := float(player.mana) / float(player.max_mana) * 100.0

	manabar.value = mana_percent
	mana_label.text = str(player.mana) + "/" + str(player.max_mana)
