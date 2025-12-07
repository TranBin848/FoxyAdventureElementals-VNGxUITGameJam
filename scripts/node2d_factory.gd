extends Marker2D
class_name Node2DFactory

signal created(product)

@export var product_packed_scene: PackedScene
@export var target_container_name: StringName = "ProductsContainer"

var container: Node = null  # store reference
var parent_node: Node = null

func _ready() -> void:
	# Try find "Stage"
	parent_node = find_parent("Stage")

	# If Stage doesn't exist → use scene root
	if parent_node == null:
		parent_node = get_tree().current_scene

	# Try find existing container
	container = parent_node.find_child(target_container_name)

	# Create container if missing
	if container == null:
		container = Node.new()
		container.name = target_container_name
		parent_node.add_child.call_deferred(container)

func create(_product_packed_scene := product_packed_scene) -> Node2D:
	if _product_packed_scene == null:
		push_warning("Node2DFactory: No PackedScene assigned.")
		return null

	if container == null:
		push_warning("Node2DFactory: Container not initialized.")
		return null

	var product: Node2D = _product_packed_scene.instantiate()
	product.global_position = global_position
	
	container.add_child(product)
	created.emit(product)

	return product
