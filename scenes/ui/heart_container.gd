extends HBoxContainer
@export var player: Player
@export var heart_full: Texture2D
@export var heart_empty: Texture2D

func _ready():
	player.connect("health_changed", Callable(self, "update_hearts"))
	update_hearts()

func update_hearts():
	# Clear existing hearts
	for child in get_children():
		child.queue_free()

	# Draw hearts according to current health
	for i in range(player.max_health):
		var heart = TextureRect.new()
		heart.texture = heart_full if i < player.health else heart_empty
		heart.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
		add_child(heart)
