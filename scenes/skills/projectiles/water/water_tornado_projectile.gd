extends ProjectileBase
class_name WaterTornadoProjectile

@export var pull_force: float = 300.0
@export var pull_duration: float = 1.0
@export var pull_stop_distance: float = 4.0
@export var lift_speed: float = 50.0 # tốc độ bay lên

var pulling: bool = false
var pull_timer: float = 0.0

var pulled_enemies: Array[EnemyCharacter] = []

func _ready() -> void:
	if has_node("HitArea2D"):
		var hit_area: HitArea2D = $HitArea2D
		hit_area.damage = damage
		hit_area.elemental_type = elemental_type

func _physics_process(delta: float) -> void:
	super._physics_process(delta)

	if pulling:
		pull_timer += delta
		if pull_timer >= pull_duration:
			_stop_pulling()
			return

		for enemy in pulled_enemies:
			if not is_instance_valid(enemy):
				continue

			var dir: Vector2 = global_position - enemy.global_position
			var distance := dir.length()
			if distance <= pull_stop_distance:
				continue

			var pull_velocity: Vector2 = dir.normalized() * pull_force * delta
			enemy.global_position += pull_velocity


# Callback khi có va chạm với enemy
func _on_hit_area_2d_hitted(area: Variant) -> void:
	if area == null:
		return
	var parent_dir_node: Node = area.get_parent()
	if parent_dir_node == null:
		return
	var enemy_node: Node = parent_dir_node.get_parent()
	if enemy_node is EnemyCharacter:
		var enemy: EnemyCharacter = enemy_node as EnemyCharacter

		# Nếu enemy chưa bị hút thì thêm vào danh sách
		if enemy not in pulled_enemies:
			pulled_enemies.append(enemy)
			#enemy.is_movable = false

		pulling = true
		pull_timer = 0.0
		


func _stop_pulling() -> void:
	if not pulling:
		return
	pulling = false

	# Trả lại quyền di chuyển cho toàn bộ enemy
	for enemy in pulled_enemies:
		if enemy and is_instance_valid(enemy):
			enemy.is_movable = true
	pulled_enemies.clear()

	if $AnimatedSprite2D.animation != "WaterTornado_End":
		$AnimatedSprite2D.play("WaterTornado_End")
		set_physics_process(false)
		$AnimatedSprite2D.connect("animation_finished", Callable(self, "_on_animation_finished"), CONNECT_ONE_SHOT)


func _on_body_entered(body: Node2D) -> void:
	if $AnimatedSprite2D.animation != "WaterTornado_End":
		$AnimatedSprite2D.play("WaterTornado_End")
		set_physics_process(false)
		$AnimatedSprite2D.connect("animation_finished", Callable(self, "_on_animation_finished"), CONNECT_ONE_SHOT)


func _on_animation_finished() -> void:
	queue_free()
