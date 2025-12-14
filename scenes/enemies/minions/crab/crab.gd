extends EnemyCharacter

var zoom_minimum = Vector2 (0.1, 0.1)
var zoom_maximum = Vector2 (2.5, 2.5)
var zoom_speed = Vector2(0.1, 0.1)

func _ready() -> void:
	super._ready()
	fsm = FSM.new(self, $States, $States/Moving)

@onready var camera: Camera2D = $Camera2D

func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.is_pressed():
			if event.button_index == MOUSE_BUTTON_WHEEL_UP:
				if camera.zoom > zoom_minimum:
					camera.zoom -= zoom_speed
			
			if event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
				if camera.zoom < zoom_maximum:
					camera.zoom += zoom_speed
