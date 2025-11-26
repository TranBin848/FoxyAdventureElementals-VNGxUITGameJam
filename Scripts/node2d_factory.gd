extends Marker2D
class_name Node2DFactory

signal created(product)

@export var product_packed_scene: PackedScene
@export var target_container_name: StringName = "ProductsContainer"


func create(_product_packed_scene := product_packed_scene) -> Node2D:
	if _product_packed_scene == null:
		push_warning("Node2DFactory: No PackedScene assigned.")
		return null

	var product: Node2D = _product_packed_scene.instantiate()
	product.global_position = global_position

	# Create a fresh container every time
	var container = Node.new()
	container.name = str(target_container_name)
	get_parent().add_child(container)

	container.add_child(product)

	created.emit(product)
	return product
