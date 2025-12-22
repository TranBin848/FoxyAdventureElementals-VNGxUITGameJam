extends Marker2D
class_name Node2DFactory

signal created(product)

@export var product_packed_scene: PackedScene
@export var target_container_name: StringName = "ProductsContainer"

var parent_node: Node = null
var container: Node = null  # Store reference after initialization
var _is_ready: bool = false

func _ready() -> void:
	parent_node = find_parent("Stage")
	if parent_node == null:
		parent_node = get_tree().current_scene

	container = parent_node.find_child(target_container_name, true, false)
	if container == null:
		container = Node.new()
		container.name = target_container_name
		parent_node.add_child.call_deferred(container)

	_is_ready = true

func create(_product_packed_scene := product_packed_scene) -> Node2D:
	if _product_packed_scene == null:
		push_warning("Node2DFactory: No PackedScene assigned.")
		return null
	
	# Ensure initialization is complete
	if not _is_ready:
		push_warning("Node2DFactory: Factory not ready yet.")
		return null
	
	# Use stored reference instead of searching
	if container == null or not is_instance_valid(container):
		push_warning("Node2DFactory: Container not initialized.")
		return null
	
	var product: Node2D = _product_packed_scene.instantiate()
	product.global_position = global_position
	
	container.add_child(product)
	created.emit(product)
	
	return product
