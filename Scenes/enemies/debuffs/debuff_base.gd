class_name Debuff
extends Node2D

enum DebuffStates {Start, Perform, End}

@export var start_time: float
@export var start_animation: String = "start"
@export var perform_time: float
@export var perform_animation: String = "perform"
@export var end_time: float
@export var end_animation: String = "end"

var target: EnemyCharacter
var animated_sprite: AnimatedSprite2D
var current_state: DebuffStates = DebuffStates.Start

func init(enemy: EnemyCharacter) -> void:
	target = enemy

func _ready() -> void:
	#current_state = DebuffStates.Start
	_init_animated_sprite()
	
func _init_animated_sprite() -> void:
	if has_node("AnimatedSprite2D"): animated_sprite = $AnimatedSprite2D

func _update(delta: float):
	match current_state:
		DebuffStates.Start: start_state(delta)
		DebuffStates.Perform: perform_state(delta)
		DebuffStates.End: perform_state(delta)
	pass
	
func _end_debuff() -> void:
	self.free()
	
func start_state(delta: float) -> void:
	current_state = DebuffStates.Perform
	pass

func perform_state(delta: float) -> void:
	current_state = DebuffStates.End
	pass

func end_state(delta: float) -> void:
	if target != null: target.remove_debuff(self)
	_end_debuff()
	pass
