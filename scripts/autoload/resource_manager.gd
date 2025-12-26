extends Node

# Dictionary to track the status of requested paths
var _pending_resources = {}

func _process(_delta):
	# Optional: If you want to react to loads finishing immediately, 
	# you could poll here. For now, we fetch on demand.
	pass

## Call this early! (e.g. when player enters a general zone)
## Returns true if the request was successfully sent or already loaded.
func queue_resource(path: String, high_priority: bool = false) -> bool:
	if path in _pending_resources:
		return true # Already queued or loaded
	
	# Check if it's already cached in memory by Godot
	if ResourceLoader.has_cached(path):
		_pending_resources[path] = ResourceLoader.THREAD_LOAD_LOADED
		return true

	# Start the background load
	# use_sub_threads = true prevents main thread hitching
	var error = ResourceLoader.load_threaded_request(path, "", true)
	
	if error == OK:
		_pending_resources[path] = ResourceLoader.THREAD_LOAD_IN_PROGRESS
		return true
	else:
		return false

## Call this when you are ready to spawn the object.
## Returns the Resource if ready, or null if still loading.
func get_resource(path: String) -> Resource:
	if not path in _pending_resources:
		# Emergency: It wasn't queued. Load it synchronously (might lag)
		return load(path)
		
	var status = ResourceLoader.load_threaded_get_status(path)
	
	if status == ResourceLoader.THREAD_LOAD_LOADED:
		return ResourceLoader.load_threaded_get(path)
		
	elif status == ResourceLoader.THREAD_LOAD_IN_PROGRESS:
		# It's not ready yet. 
		# Option A: Return null (game logic waits)
		# Option B: Force finish (causes lag but guarantees return)
		print("Warning: Asset not ready, forcing synchronous load: ", path)
		return ResourceLoader.load_threaded_get(path) # This blocks until done
		
	return null

## Optional: Clean up if you change levels
func clear_queue():
	_pending_resources.clear()
