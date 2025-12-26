class_name BaseCharacter
extends CharacterBody2D

## Base character class that provides common functionality for all characters

# --- MOVEMENT SETTINGS ---
@export var movement_speed: float = 200.0
var is_movable: bool = true
@export var gravity: float = 700.0
var ignore_gravity := false
var direction: int = 1
@export var _next_direction: int = 1
var jump_speed: float = 400.0
var jump_multiplier: float = 1.0
var platform_vel

# --- STATS ---
@export var attack_damage: int = 1
@export var max_health: int = 100
@export var max_mana: int = 1000
@export var elemental_type: ElementsEnum.Elements = ElementsEnum.Elements.NONE
var health: int = max_health
var mana: int = max_mana

# --- SIGNALS ---
signal hurt
signal health_changed
signal died
signal mana_changed

# --- ELEMENTAL TABLES ---
const restraint_table = { 
	ElementsEnum.Elements.METAL: [ElementsEnum.Elements.WOOD], 
	ElementsEnum.Elements.WOOD: [ElementsEnum.Elements.EARTH], 
	ElementsEnum.Elements.WATER: [ElementsEnum.Elements.FIRE], 
	ElementsEnum.Elements.FIRE: [ElementsEnum.Elements.METAL], 
	ElementsEnum.Elements.EARTH: [ElementsEnum.Elements.WATER] }
const creation_table = { 
	ElementsEnum.Elements.METAL: [ElementsEnum.Elements.WATER], 
	ElementsEnum.Elements.WATER: [ElementsEnum.Elements.WOOD], 
	ElementsEnum.Elements.WOOD: [ElementsEnum.Elements.FIRE], 
	ElementsEnum.Elements.FIRE: [ElementsEnum.Elements.EARTH], 
	ElementsEnum.Elements.EARTH: [ElementsEnum.Elements.METAL] }

# --- ANIMATION SYSTEM ---
var fsm: FSM = null
var animated_sprite: AnimatedSprite2D = null
@onready var extra_sprites: Array[AnimatedSprite2D] = []

# Current State
var current_animation: String = ""

# Next Frame Buffers
var _next_animation: String = ""
var _next_animated_sprite: AnimatedSprite2D = null

func _ready() -> void:
	# Initialize the first sprite immediately
	if has_node("Direction/AnimatedSprite2D"):
		set_animated_sprite($Direction/AnimatedSprite2D)
		_swap_active_sprite_node()
	health = max_health

func _physics_process(delta: float) -> void:
	# 1. Animation & Visuals
	_check_changed_animation() # Logic to swap sprites/anims
	_sync_extra_sprites()      # Logic to keep silhouettes locked to main sprite
	
	# 2. Update Palette
	if animated_sprite != null:
		_update_elemental_palette()

	# 3. FSM Update
	if fsm != null:
		fsm._update(delta)
	
	# 4. Movement
	_update_movement(delta)
	
	# 5. Direction
	_check_changed_direction()

# ------------------------------------------------------------------
# ANIMATION & SPRITE LOGIC (FIXED)
# ------------------------------------------------------------------

func change_animation(new_animation: String) -> void:
	_next_animation = new_animation

func change_sprite(new_sprite: AnimatedSprite2D) -> void:
	_next_animated_sprite = new_sprite

func set_animated_sprite(new_animated_sprite: AnimatedSprite2D) -> void:
	_next_animated_sprite = new_animated_sprite

func get_animation_name() -> String:
	return animated_sprite.name if animated_sprite else ""

func get_current_sprite_name() -> String:
	return get_animation_name()
	
# Main function called in physics_process to reconcile state
func _handle_visual_updates() -> void:
	var sprite_changed: bool = _next_animated_sprite != animated_sprite
	var anim_changed: bool = _next_animation != current_animation
	
	# 1. If the Sprite Node changed (e.g. Weapon Switch), swap the nodes first
	if sprite_changed:
		_swap_active_sprite_node()
		# If we swapped sprites, we MUST replay the animation, 
		# even if the animation name hasn't changed.
		anim_changed = true 

	# 2. If the Animation changed OR we just swapped sprites, play the animation
	if anim_changed:
		current_animation = _next_animation
		_play_animation_on_all_sprites(current_animation)


func _check_changed_animation() -> void:
	var sprite_changed: bool = _next_animated_sprite != animated_sprite
	var anim_changed: bool = _next_animation != current_animation
	
	# 1. Handle Sprite Swap (Weapon Change)
	if sprite_changed:
		# Capture old frame data before swapping
		var old_frame = animated_sprite.frame if animated_sprite else 0
		var old_progress = animated_sprite.frame_progress if animated_sprite else 0.0
		
		_swap_active_sprite_node()
		
		# Sync the new sprite to the old sprite's frame immediately
		if animated_sprite and current_animation != "":
			if animated_sprite.sprite_frames.has_animation(current_animation):
				animated_sprite.play(current_animation)
				animated_sprite.set_frame_and_progress(old_frame, old_progress)
		
		# Force anim update to sync silhouettes
		anim_changed = true 

	# 2. Handle Animation Change (Idle -> Run)
	if anim_changed:
		current_animation = _next_animation
		_play_animation_on_all_sprites(current_animation)

func _swap_active_sprite_node() -> void:
	if is_instance_valid(animated_sprite):
		animated_sprite.hide()
		animated_sprite.stop()
	
	if is_instance_valid(_next_animated_sprite):
		animated_sprite = _next_animated_sprite
		animated_sprite.show()
	else:
		animated_sprite = null

func _play_animation_on_all_sprites(anim_name: String) -> void:
	if not is_instance_valid(animated_sprite): return
		
	# Play Main Sprite
	if animated_sprite.sprite_frames.has_animation(anim_name):
		animated_sprite.play(anim_name)
	
	# Play Extra Sprites (Silhouettes)
	# We reset them to frame 0 here, but _sync_extra_sprites locks them tight every frame
	for sprite in extra_sprites:
		if is_instance_valid(sprite) and sprite.sprite_frames.has_animation(anim_name):
			sprite.play(anim_name)
			sprite.frame = animated_sprite.frame 
			sprite.frame_progress = animated_sprite.frame_progress

# 🔥 NEW: Locks silhouette frames to the main sprite every physics tick
func _sync_extra_sprites() -> void:
	if not is_instance_valid(animated_sprite): return
	
	for sprite in extra_sprites:
		if is_instance_valid(sprite) and sprite.visible:
			# Sync Transform Properties
			sprite.flip_h = animated_sprite.flip_h
			sprite.offset = animated_sprite.offset
			
			# Sync Animation Frame (Crucial for correct silhouette visual)
			if sprite.animation == animated_sprite.animation:
				sprite.frame = animated_sprite.frame
				sprite.frame_progress = animated_sprite.frame_progress

# ------------------------------------------------------------------
# MOVEMENT & PHYSICS LOGIC
# ------------------------------------------------------------------

func _update_elemental_palette() -> void: pass

func _update_movement(delta: float) -> void:
	if not is_movable:
		velocity = Vector2.ZERO
		return
	if not ignore_gravity:
		velocity.y += gravity * delta
	move_and_slide()

func turn_around() -> void:
	if _next_direction != direction: return
	_next_direction = -direction

func is_left() -> bool: return direction == -1
func is_right() -> bool: return direction == 1
func turn_left() -> void: _next_direction = -1
func turn_right() -> void: _next_direction = 1

func jump() -> void:
	if is_on_floor():
		# Get platform velocity and subtract it
		platform_vel = get_platform_velocity()
	else: platform_vel = Vector2.ZERO
	velocity.y = -jump_speed * jump_multiplier - platform_vel.y


func stop_move() -> void:
	velocity.x = 0; velocity.y = 0

func _check_changed_direction() -> void:
	if _next_direction != direction:
		direction = _next_direction
		_on_changed_direction()
		if has_node("Direction"):
			$Direction.scale.x = direction

func _on_changed_direction() -> void: pass
func change_direction(new_direction: int) -> void: _next_direction = new_direction

# ------------------------------------------------------------------
# COMBAT LOGIC
# ------------------------------------------------------------------

func take_damage(damage: int) -> void:
	health -= damage
	hurt.emit(); health_changed.emit()
	if health <= 0: died.emit()

func fire() -> void: pass
