extends RigidBody2D

@export var blade_scene: PackedScene
@export var rotation_speed: float = 10
var direction: float = 1

func _physics_process(delta: float) -> void:
	rotation += rotation_speed * delta * direction
	
func _on_body_entered(_body: Node) -> void:
	drop_blade()
	#print("enterbody:" + _body.name)

func _on_hit_area_2d_hitted(area: Variant) -> void:
	#print("enterarea:" + area.name)
	drop_blade()
	
func drop_blade() -> void:
	#print("drop")
	var blade = blade_scene.instantiate()
	blade.global_position = global_position
	get_tree().current_scene.add_child(blade)
	queue_free()
