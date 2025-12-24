# res://skills/projectiles/ProjectileBase.gd
extends Area2D
class_name ProjectileBase

var speed: float
var direction: Vector2 = Vector2.RIGHT
var damage: float
var elemental_type: ElementsEnum.Elements = ElementsEnum.Elements.NONE
var affected_enemies: Array[EnemyCharacter] = []


func setup(skill: Skill, dir: Vector2) -> void:
	#print(skill.damage)
	#print(skill.elemental_type)
	speed = skill.speed
	damage = skill.damage
	elemental_type = skill.elemental_type
	direction = dir.normalized() if dir.length() > 0 else Vector2.RIGHT
	
	if has_node("HitArea2D"):
		var hit_area: HitArea2D = $HitArea2D
		hit_area.damage = damage
		hit_area.elemental_type = elemental_type
		#print("✅ Gán HitArea cho WaterTornado:", damage, elemental_type)
		
	# Play animation if có AnimatedSprite2D
	if has_node("AnimatedSprite2D"):
		$AnimatedSprite2D.play(skill.animation_name)
	
	if skill.animation_name != "WaterTornado":
		rotation = direction.angle()


func _physics_process(delta: float) -> void:
	_move(delta)

func _move(delta: float) -> void:
	position += speed * direction * delta

func _on_visible_on_screen_notifier_2d_screen_exited() -> void:
	queue_free()
	
func play(animation_name: String):
	$AnimatedSprite2D.play(animation_name)
	
func change_position(offset_y: float) -> void:
	$AnimatedSprite2D.position.y += offset_y
