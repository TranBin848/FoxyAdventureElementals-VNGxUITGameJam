extends ProjectileBase
class_name ToxicBreathProjectile

@export var length: float = 32.0          # How far in front of player
@export var offset_y: float = -8.0        # Vertical offset
@export var lifetime_sec: float = 3.0     # How long the breath persists
@export var breath_anim: String = "ToxicBreath"  # Animation name on AnimatedSprite2D

@onready var hit_area: Area2D = $HitArea2D
@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D

var center_position: Vector2
var is_active: bool = false

func _ready() -> void:
	# Place breath in front of player, based on direction.x
	var dir_x := direction.x
	if dir_x == 0:
		dir_x = 1  # default right if not set

	var forward_offset := Vector2(length * dir_x, offset_y)
	global_position += forward_offset
	center_position = global_position
	
	# Flip sprite according to facing direction
	if sprite:
		sprite.flip_h = dir_x < 0
		sprite.play(breath_anim)
	
	# Enable hit area on this projectile
	if hit_area:
		hit_area.monitorable = true
		hit_area.monitoring = true
	
	# This projectile is static
	speed = 0
	set_physics_process(true)
	
	# Start lifetime timer
	sprite.animation_finished.connect(_on_animation_completed)

func _physics_process(delta: float) -> void:
	# Static toxic breath, no movement
	super._physics_process(delta)
	rotation = 0

func _on_hit_area_2d_hitted(area: Variant) -> void:
	var enemy = _get_enemy_from_area(area)
	if enemy:
		print("Hit area detected enemy: ", enemy.name)
		if not affected_enemies.has(enemy):
			affected_enemies.append(enemy)
			print("Added enemy to affected_enemies. Total: ", affected_enemies.size())

func _get_enemy_from_area(area: Node) -> EnemyCharacter:
	var current = area
	for i in range(5):
		if current is EnemyCharacter:
			return current
		if current.get_parent():
			current = current.get_parent()
		else:
			break
	return null

func _on_body_entered(_body: Node2D) -> void:
	# Not used for this static AoE, HitArea2D handles damage
	pass

func _on_animation_completed() -> void:
	# 1. Apply poison once to all affected enemies
	for i in range(affected_enemies.size()):
		var enemy = affected_enemies[i]
		if enemy and is_instance_valid(enemy) and enemy.is_inside_tree():
			enemy.apply_poison_effect()
		else:
			print("Enemy ", i, " invalid")
	
	# 2. Disable collision so no more hits happen
	if hit_area:
		hit_area.monitoring = false
		hit_area.monitorable = false
	
	# 3. Optionally hide sprite
	if sprite:
		sprite.visible = false
	
	# 4. Free this projectile so it cannot hit anymore
	queue_free()
