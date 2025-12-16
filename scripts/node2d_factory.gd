extends Marker2D
class_name Node2DFactory

signal created(product)

@export var product_packed_scene: PackedScene
@export var target_container_name: StringName = "ProductsContainer"

# REMOVED: Don't store container reference
# var container: Node = null  # ← This causes memory leak!
var parent_node: Node = null

func _ready() -> void:
	parent_node = find_parent("Stage")
	
	if parent_node == null:
		parent_node = get_tree().current_scene
	
	# Get or create container but don't store it
	var container = parent_node.find_child(target_container_name)
	if container == null:
		container = Node.new()
		container.name = target_container_name
		parent_node.call_deferred("add_child", container)

func create(_product_packed_scene := product_packed_scene) -> Node2D:
	if _product_packed_scene == null:
		push_warning("Node2DFactory: No PackedScene assigned.")
		return null
	
	# Find container each time instead of storing reference
	var container = parent_node.find_child(target_container_name)
	if container == null:
		push_warning("Node2DFactory: Container not initialized.")
		return null
	
	var product: Node2D = _product_packed_scene.instantiate()
	product.global_position = global_position
	
	container.add_child(product)
	created.emit(product)
	
	return product
