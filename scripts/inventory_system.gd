extends Node
class_name InventorySystem

signal coin_changed(new_amount: int)
signal coin_collected(item_type: String, amount: int)

var coins: int = 0
var keys: int = 0

func _ready() -> void:
	pass

func add_coin(amount: int) -> void:
	coins += amount
	
	# HOOK HERE
	GameProgressManager.trigger_event("COIN")
	
	coin_changed.emit(coins)
	coin_collected.emit("coin", amount)
	print("Collected ", amount, " coins. Total: ", coins)
	
func add_key(_amount: int = 1) -> void:
	keys += _amount
	
	# HOOK HERE
	GameProgressManager.trigger_event("KEY")
	
	coin_collected.emit("key", _amount)
	print("Collected ", _amount, " keys. Total: ", keys)
	
func use_key() -> bool:
	if get_keys() > 0:
		keys -= 1
		return true
	return false
	
func use_coin(amount: int) -> bool:
	if get_coins() >= amount:
		coins -= amount
		coin_changed.emit(coins)
		return true
	return false
	
func save_data() -> Dictionary:
	return {"coins": coins, "keys": keys}
	
func load_data(saved_data: Dictionary) -> void:
	coins = saved_data.get("coins", 0)
	keys = saved_data.get("keys", 0)
	
func clear_all() -> void:
	keys = 0
	coins = 0

func has_key() -> bool:
	return keys > 0	

func get_coins() -> int:
	return coins

func get_keys() -> int:
	return keys
