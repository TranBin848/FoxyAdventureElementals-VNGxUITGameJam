extends "res://scenes/enemies/spawner/spawner.gd"
class_name BossSpawner

# Spawner đặc biệt cho boss - chỉ spawn con tiếp theo khi con trước chết

var spawned_enemy: Node = null  # Lưu enemy đã spawn

func spawn_enemy() -> bool:
	# Kiểm tra nếu enemy trước vẫn còn sống thì không spawn
	if is_instance_valid(spawned_enemy) and spawned_enemy.health > 0:
		# Enemy cũ vẫn còn sống, không spawn
		return true
	
	# Enemy cũ đã chết hoặc chưa spawn, tiến hành spawn mới
	if enemy_to_spawn == null or enemy_to_spawn.size() == 0: 
		print("Please assign an enemy for the spawner")
		return true
	if health <= 0: 
		return false
	
	# Chỉ spawn 1 con
	randomize()
	var random_side = randi() % 2
	var random_distance: float = 0
	if random_side == 0:
		random_distance = randf_range(-spawn_max_distance, -spawn_min_distance)
	else: 
		random_distance = randf_range(spawn_min_distance, spawn_max_distance)
	
	var random_index: int = randi_range(0, enemy_to_spawn.size() - 1)
	var enemy = enemy_to_spawn[random_index].instantiate()
	GameManager.current_stage.find_child("Enemies").add_child(enemy)
	
	if enemy is EnemyCharacter: 
		(enemy as EnemyCharacter).position.x = position.x + random_distance
		(enemy as EnemyCharacter).position.y = position.y
		(enemy as EnemyCharacter).elemental_type = elemental_type
		if skill_drops != null and skill_drops.size() > 0:
			(enemy as EnemyCharacter).skill_to_drop = skill_drops[randi_range(0, skill_drops.size() - 1)]
		(enemy as EnemyCharacter)._ready()
	
	# Lưu lại enemy đã spawn
	spawned_enemy = enemy
	
	# Giảm máu spawner
	health -= 1
	health_changed.emit()
	
	if health <= 0: 
		return false
	
	reset_spawn_timer()
	return true
