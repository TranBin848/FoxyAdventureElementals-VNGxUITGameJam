class_name PlayerStat
extends Resource

@export_group("Display")
@export var type: String = ""       # e.g., "max_health"
@export var display_name: String = ""
@export_multiline var description: String = ""
@export var icon: Texture2D

@export_group("Settings")
@export var value_per_point: int = 1
@export var max_points: int = 99
@export var cost_per_point: int = 1
