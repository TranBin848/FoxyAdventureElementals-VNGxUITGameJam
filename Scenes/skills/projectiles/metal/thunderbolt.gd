extends ProjectileBase
class_name ThunderboltProjectile

@export var lightning_scene: PackedScene = preload("res://scenes/skills/projectiles/metal/lightning.tscn")
@export var lightning_spawn_delay_sec: float = 1.0
@export var hit_collection_time: float = 0.15  # Time to collect multiple hits

var has_triggered: bool = false
var hit_collection_timer: Timer = null

func _ready() -> void:
	AudioManager.play_sound("skill_thunderbolt")
	$AnimatedSprite2D.play("Thunderbolt_Start")
	$AnimatedSprite2D.animation_finished.connect(_on_sprite_animation_finished)
	
	# Create timer for collecting hits
	hit_collection_timer = Timer.new()
	hit_collection_timer.one_shot = true
	hit_collection_timer.timeout.connect(_trigger_death_and_spawn_lightning)
	add_child(hit_collection_timer)

func _on_sprite_animation_finished() -> void:
	if $AnimatedSprite2D.animation == "Thunderbolt_Start":
		$AnimatedSprite2D.play("Thunderbolt_Flying")

func _on_hit_area_2d_hitted(area: Variant) -> void:
	var enemy = _get_enemy_from_area(area)
	if enemy:
		print("Hit area detected enemy: ", enemy.name)
		enemy.enter_stun(global_position)
		if not affected_enemies.has(enemy):
			affected_enemies.append(enemy)
			print("Added enemy to affected_enemies. Total: ", affected_enemies.size())
		
		# Start or restart the collection timer for enemies
		if not has_triggered:
			hit_collection_timer.start(hit_collection_time)

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

func _on_body_entered(body: Node2D) -> void:
	if body is EnemyCharacter:
		print("Body entered: ", body.name)
		body.enter_stun(global_position)
		if not affected_enemies.has(body):
			affected_enemies.append(body)
			print("Added enemy to affected_enemies. Total: ", affected_enemies.size())
		
		# Start or restart the collection timer for enemies
		if not has_triggered:
			hit_collection_timer.start(hit_collection_time)
	else:
		# Hit terrain/wall - trigger immediately with all collected enemies
		print("Hit terrain, triggering immediately")
		if hit_collection_timer.is_stopped() or hit_collection_timer.time_left > 0:
			hit_collection_timer.stop()
		_trigger_death_and_spawn_lightning()

func _trigger_death_and_spawn_lightning() -> void:
	if has_triggered:
		return
	
	has_triggered = true
	print("Triggering death and lightning spawn. Total affected enemies: ", affected_enemies.size())
	
	if $AnimatedSprite2D.animation != "Thunderbolt_End":
		set_physics_process(false)
		$AnimatedSprite2D.play("Thunderbolt_End")
		_spawn_lightnings_after_delay()

func _spawn_lightnings_after_delay() -> void:
	var stunned_enemies := affected_enemies.duplicate()
	
	print("=== Spawning lightnings ===")
	print("Total stunned enemies: ", stunned_enemies.size())
	for i in range(stunned_enemies.size()):
		print("  Enemy ", i, ": ", stunned_enemies[i].name if stunned_enemies[i] else "null")
	
	await get_tree().create_timer(lightning_spawn_delay_sec).timeout
	if not is_inside_tree():
		return
	
	if lightning_scene:
		for i in range(stunned_enemies.size()):
			var enemy = stunned_enemies[i]
			if enemy and is_instance_valid(enemy) and enemy.is_inside_tree():
				print("Spawning lightning for enemy: ", enemy.name)
				
				var lightning: LightningProjectile = lightning_scene.instantiate()
				lightning.global_position = enemy.global_position
				lightning.damage = damage
				lightning.elemental_type = elemental_type
				lightning.affected_enemies = [enemy]
				
				get_parent().add_child(lightning)
			else:
				print("Enemy ", i, " invalid")
	
	queue_free()
