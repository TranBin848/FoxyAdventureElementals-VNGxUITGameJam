class_name Logger
extends RefCounted

func log(message: String) -> void:
	# Abstract — subclasses override this
	push_error("Logger.log() is abstract. Implement in subclass.")
