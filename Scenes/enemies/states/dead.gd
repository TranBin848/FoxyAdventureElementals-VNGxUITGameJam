extends EnemyState
@export var despawn_time: float = 2

var shader_material: Material
var max_line_opaque: float = 0
var max_glow_opaque: float = 0

func _enter() -> void:
	obj.change_animation("dead")
	obj.velocity.x = 0
	obj.disable_collision()
	timer = despawn_time
	get_shader_values()
	
func _update( _delta ):
	var time_ratio: float = timer / despawn_time
	obj.animated_sprite.modulate.a = time_ratio
	if shader_material != null:
		shader_material.set("shader_parameter/line_opacity", max_line_opaque * time_ratio)
		shader_material.set("shader_parameter/glow_opacity", max_glow_opaque * time_ratio)
		pass
	if update_timer(_delta):
		obj.queue_free()
	super._update(_delta)

func get_shader_values() -> void:
	shader_material = obj.animated_sprite.material
	
	for item in shader_material.get_property_list():
		if (item.name == "shader_parameter/line_opacity"):
			max_line_opaque = item.hint
		if (item.name == "shader_parameter/glow_opacity"):
			max_glow_opaque = item.hint

func take_damage(direction: Variant, damage: int = 1) -> void:
	pass
