#extends Node2D
#
#@export var LOOP_SCENE: PackedScene
#@export var ANCHOR_SCENE: PackedScene
#@export var PIN_SCENE: PackedScene
#@export var loops: int = 5
#
#
#func _ready():
	#var parent = $Anchor
	#var child = null
#
	#for i in range(loops):
		#child = addLoop(parent, LOOP_SCENE.instantiate(), 12)
		#addPin(parent, child)
		#parent = child
#
	#child = addLoop(parent, ANCHOR_SCENE.instantiate(), 12)
	#addPin(parent, child)
	#
	#
#func addLoop(parent, loop, offset):
	#loop.position = parent.position
	#loop.position.y += offset
	#add_child(loop)
	#return loop
#
#
#func addPin(parent, child):
	#var pin = PIN_SCENE.instantiate()
	#pin.node_a = parent.get_path()
	#pin.node_b = child.get_path()
	#parent.add_child(pin)

extends Line2D
class_name EnergyLine

@export var a: Node2D
@export var b: Node2D

func _process(_delta):
	clear_points()
	add_point(a.global_position)
	add_point(b.global_position)
	
	var length := a.global_position.distance_to(b.global_position) - 10 
	$Sprite2D.region_rect.size.x = length
	$Sprite2D.global_position = (a.global_position + b.global_position) * 0.5
	$Sprite2D.rotation = (b.global_position - a.global_position).angle()
