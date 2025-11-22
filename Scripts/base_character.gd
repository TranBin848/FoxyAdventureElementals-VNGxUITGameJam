class_name BaseCharacter
extends CharacterBody2D

## Base character class that provides common functionality for all characters

@export var movement_speed: float = 200.0
var is_movable: bool = true

@export var gravity: float = 700.0
var ignore_gravity := false
var direction: int = 1

@export var _next_direction: int = 1
@export var attack_damage: int = 1
@export var max_health: int = 100
@export var max_mana: int = 100
@export var elemental_type: int = 0 #0: none, 1: fire, 2: earth, 3: water
var health: int = max_health
var mana: int = max_mana
signal health_changed
signal mana_changed
signal died


var jump_speed: float = 400.0
var fsm: FSM = null
var current_animation = null
var animated_sprite: AnimatedSprite2D = null
@onready var extra_sprites: Array[AnimatedSprite2D] = []

var _next_animation = null

var _next_animated_sprite: AnimatedSprite2D = null

func _ready() -> void:
	set_animated_sprite($Direction/AnimatedSprite2D)
	health = max_health

func _physics_process(delta: float) -> void:
	# Animation - must run first to set animated_sprite
	_check_changed_animation()
	
	# Update palette after sprite is set
	if animated_sprite != null:
		_update_elemental_palette()

	if fsm != null:
		fsm._update(delta)
	# Movement
	_update_movement(delta)
	# Direction
	_check_changed_direction()

func _update_elemental_palette() -> void:
	pass

func _update_movement(delta: float) -> void:
	if not is_movable:
		velocity = Vector2.ZERO
		return
	if not ignore_gravity:
		velocity.y += gravity * delta
	move_and_slide()

func turn_around() -> void:
	if _next_direction != direction:
		return
	_next_direction = -direction

func is_left() -> bool:
	return direction == -1

func is_right() -> bool:
	return direction == 1

func turn_left() -> void:
	_next_direction = -1

func turn_right() -> void:
	_next_direction = 1

func jump() -> void:
	velocity.y = -jump_speed

func stop_move() -> void:
	velocity.x = 0
	velocity.y = 0

func take_damage(damage: int) -> void:
	health -= damage
	health_changed.emit()
	if health <= 0:
		died.emit()

# Change the animation of the character on the next frame
func change_animation(new_animation: String) -> void:
	_next_animation = new_animation

# Change the direction of the character on the last frame
func change_direction(new_direction: int) -> void:
	_next_direction = new_direction

# Get the name of the current animation
func get_animation_name() -> String:
	return current_animation.name

func set_animated_sprite(new_animated_sprite: AnimatedSprite2D) -> void:
	_next_animated_sprite = new_animated_sprite

# Check if the animation or animated sprite has changed and play the new animation
func _check_changed_animation() -> void:
	var need_play := false
	if _next_animation != current_animation:
		current_animation = _next_animation
		need_play = true
	if _next_animated_sprite != animated_sprite:
		if animated_sprite != null:
			animated_sprite.hide()
		animated_sprite = _next_animated_sprite
		animated_sprite.show()
		need_play = true
	if need_play and current_animation != null:
		if animated_sprite != null:
			animated_sprite.play(current_animation)
		for sprite in extra_sprites:
			if sprite != null:
				sprite.play(current_animation)

# Check if the direction has changed and set the new direction
func _check_changed_direction() -> void:
	if _next_direction != direction:
		direction = _next_direction
		_on_changed_direction()
		$Direction.scale.x = direction
		#if direction == -1:
			#$Direction.scale.x = -1
		#if direction == 1:
			#$Direction.scale.x = 1
	

func fire() -> void:
	pass

# On changed direction
func _on_changed_direction() -> void:
	pass
