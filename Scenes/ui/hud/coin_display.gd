extends PanelContainer

# Adjust this path based on your actual Scene Tree structure
@onready var coin_label: Label = $HBoxContainer/Label 

func _ready() -> void:
	# We use call_deferred to wait for the whole scene tree to settle
	# before searching for the player
	call_deferred("_setup")

func _setup() -> void:
	if GameManager.inventory_system.has_signal("coin_changed"):
		GameManager.inventory_system.coin_changed.connect(_update_coins)
	
	# Run once at start to show initial value
	_update_coins()

func _update_coins(_new_amount: int = 0) -> void:
	# We access the variable directly to be safe, 
	# but you can also use '_new_amount' if your signal passes the value.
	coin_label.text = str(GameManager.inventory_system.get_coins())
