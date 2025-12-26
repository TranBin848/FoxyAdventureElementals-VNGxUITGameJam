class_name Debuff
extends Node2D

enum DebuffStates {None, Start, Perform, End}

@export var default_start_time: float = 3
@export var default_start_animation: String = "start"
@export var default_perform_time: float = 3
@export var default_perform_animation: String = "perform"
@export var default_end_time: float = 3
@export var default_end_animation: String = "end"

@export var spirit_circle_appear_time: float = 1.5
@export var spirit_circle_strong_opaque: float = 1.0
@export var spirit_circle_weak_opaque: float = 0.25

var start_time: float = 0
var start_animation: String = ""
var perform_time: float = 0
var perform_animation: String = ""
var end_time: float = 0
var end_animation: String = ""

var target: EnemyCharacter
var animated_sprite: AnimatedSprite2D
var spirit_circle_sprite: AnimatedSprite2D
var current_state: DebuffStates = DebuffStates.Start

var timer: float = 0
var spirit_circle_timer: float = 0

func init(enemy: EnemyCharacter) -> void:
	target = enemy

func _ready() -> void:
	_init_default_time_values()
	_init_default_animation_values()
	current_state = DebuffStates.None
	_init_animated_sprite()

func _init_default_time_values() -> void:
	start_time = default_start_time
	perform_time = default_perform_time
	end_time = default_end_time
	pass

func _init_default_animation_values() -> void:
	start_animation = default_start_animation
	perform_animation = default_perform_animation
	end_animation = default_end_animation

func _init_animated_sprite() -> void:
	if has_node("AnimatedSprite2D"): animated_sprite = $AnimatedSprite2D
	if has_node("CircleAnimatedSprite2D"): 
		spirit_circle_sprite = $CircleAnimatedSprite2D
		spirit_circle_sprite.modulate.a = 0
		spirit_circle_sprite.play("default")
		spirit_circle_timer = spirit_circle_appear_time

func _update(delta: float):
	match current_state:
		DebuffStates.None: start_state_enter()
		DebuffStates.Start: start_state_update(delta)
		DebuffStates.Perform: perform_state_update(delta)
		DebuffStates.End: end_state_update(delta)
	update_circle_spirit_modulate(delta)
	pass

func start_state_enter() -> void:
	current_state = DebuffStates.Start
	timer = start_time
	if animated_sprite != null: animated_sprite.play(start_animation)
	pass

func start_state_update(delta: float) -> void:
	if update_timer(delta):
		start_state_exit()
		perform_state_enter()
	pass

func start_state_exit() -> void:
	pass

func perform_state_enter() -> void:
	current_state = DebuffStates.Perform
	timer = perform_time
	if animated_sprite != null: animated_sprite.play(perform_animation)
	pass

func perform_state_update(delta: float) -> void:
	if update_timer(delta):
		perform_state_exit()
		end_state_enter()
	pass

func perform_state_exit() -> void:
	pass

func end_state_enter() -> void:
	current_state = DebuffStates.End
	timer = end_time
	if animated_sprite != null: animated_sprite.play(end_animation)
	pass

func end_state_update(delta: float) -> void:
	if update_timer(delta):
		end_state_exit()
	pass

func end_state_exit() -> void:
	_end_debuff()
	pass

func _end_debuff() -> void:
	if target != null: target.remove_debuff(self)
	self.queue_free()

func update_timer(delta: float) -> bool:
	timer -= delta
	if timer <= 0: return true
	return false

func update_circle_spirit_modulate(delta: float) -> void:
	if spirit_circle_sprite == null: return
	if spirit_circle_timer >= spirit_circle_appear_time * 0.5:
		var elapsed_time: float = spirit_circle_appear_time - spirit_circle_timer
		spirit_circle_sprite.modulate.a = spirit_circle_strong_opaque * (elapsed_time / (spirit_circle_appear_time * 0.5))
	else:
		spirit_circle_sprite.modulate.a = spirit_circle_strong_opaque * spirit_circle_timer / (spirit_circle_appear_time * 0.5)
	spirit_circle_timer -= delta
