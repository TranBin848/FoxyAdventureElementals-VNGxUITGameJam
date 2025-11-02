# res://skills/projectiles/ProjectileBase.gd
extends Area2D
class_name ProjectileBase

var speed: float
var direction: Vector2 = Vector2.RIGHT
var damage: int

func setup(skill: Skill, dir: Vector2) -> void:
	print(skill.animation_name)
	speed = skill.speed
	damage = skill.damage
	direction = dir.normalized() if dir.length() > 0 else Vector2.RIGHT
	
	# Play animation if có AnimatedSprite2D
	if has_node("AnimatedSprite2D"):
		print(skill.animation_name)
		$AnimatedSprite2D.play(skill.animation_name)
	
	if $AnimatedSprite2D.animation != "WaterTornado":
		rotation = direction.angle()
	else:
		change_position(-36)

func _physics_process(delta: float) -> void:
	position += speed * direction * delta

func _on_visible_on_screen_notifier_2d_screen_exited() -> void:
	queue_free()
	
func play(animation_name: String):
	$AnimatedSprite2D.play(animation_name)
	
func change_position(offset_y: float) -> void:
	$AnimatedSprite2D.position.y += offset_y
