extends EnemyCharacter

@export var enemy_to_spawn: Array[PackedScene]
@export var skill_drops: Array[Script]
@export var enemy_per_spawn: int = 1
@export var spawn_interval: float = 3.0
@export var spawn_min_distance: float = 2
@export var spawn_max_distance: float = 10

var spawn_timer: float = 0

func _ready() -> void:
	super._ready()
	_init_animated_sprite()
	fsm = FSM.new(self, $States, $States/Idle)
	
func _process(delta: float) -> void:
	spawn_timer -= delta

func _init_animated_sprite() -> void:
	if has_node("Direction/AnimatedSprites"):
		var sprites_holder = $Direction/AnimatedSprites
		if sprites_holder.get_child_count() == 0:
			return
		var sprites: Array = sprites_holder.get_children()
		for sprite in sprites:
			if sprite is AnimatedSprite2D:
				var sprite_name: String = sprite.name
				if sprite_name == elements_particle[elemental_type]:
					sprite.visible = true;
					set_animated_sprite(sprite as AnimatedSprite2D)
				else: 
					sprite.visible = false;
	change_animation("spawn")
	pass

func spawn_enemy() -> bool:
	if enemy_to_spawn == null or enemy_to_spawn.size() == 0: 
		print("Please assign an enemy for the spawner")
		return true
	if health <= 0: return false
	for i in enemy_per_spawn:
		randomize()
		var random_side = randi() % 2
		var random_distance: float = 0
		if random_side == 0:
			random_distance = randf_range(-spawn_max_distance, -spawn_min_distance)
		else: random_distance = randf_range(spawn_min_distance, spawn_max_distance)
		var random_index: int = randi_range(0, enemy_to_spawn.size() - 1)
		var enemy = enemy_to_spawn[random_index].instantiate()
		GameManager.current_stage.find_child("Enemies").add_child(enemy)
		if enemy is EnemyCharacter: 
			(enemy as EnemyCharacter).position.x = position.x + random_distance
			(enemy as EnemyCharacter).position.y = position.y
			(enemy as EnemyCharacter).elemental_type = elemental_type
			(enemy as EnemyCharacter)._ready()
		health-=1
		health_changed.emit()
		if health <= 0: return false			

	reset_spawn_timer()
	return true

func reset_spawn_timer() -> void:
	spawn_timer = spawn_interval
	
func update_spawn_timer(delta: float) -> bool:
	#spawn_timer -= delta
	if (spawn_timer <= 0):
		return true
	return false
