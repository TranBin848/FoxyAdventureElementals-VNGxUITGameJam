extends TextureProgressBar

@export var enemy: EnemyCharacter

func _ready() -> void:
	if (enemy != null):
		print("enemy is not null")
		enemy.health_changed.connect(progress_changed)
	
func progress_changed() -> void:
	self.value = (float(enemy.health) / float(enemy.max_health)) * 100
