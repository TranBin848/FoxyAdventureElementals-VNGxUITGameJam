extends InteractiveArea2D

@export var linked_door: Node2D = null

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D

var is_activated: bool = false

func _ready():
	interacted.connect(_on_interacted)
	animated_sprite.play("deactivate")

func _on_interacted():
	toggle_lever()

func toggle_lever():
	is_activated = !is_activated
	
	if is_activated:
		animated_sprite.play("activate")
		if linked_door:
			linked_door.open_door()
	else:
		animated_sprite.play("deactivate")
		if linked_door:
			linked_door.close_door()
