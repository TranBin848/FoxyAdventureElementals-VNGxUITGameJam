class_name Mushroom
extends EnemyCharacter

@export var self_scene: PackedScene
@export var max_level: int = 3
@export var max_scale: Vector2 = Vector2.ONE
@export var min_scale: Vector2 = Vector2(0.5, 0.5)
@export var number_per_split: int = 2
@export var split_min_distance: float = 10
@export var split_max_distance: float = 20
@export var number_of_skill_drop: int = 3

var level: int = 1

func _ready() -> void:
	super._ready()
	fsm = FSM.new(self, $States, $States/Moving)
	scale.x = max_scale.x - ((max_scale.x - min_scale.x) / (max_level)) * (level - 1)
	scale.y = max_scale.y - ((max_scale.y - min_scale.y) / (max_level)) * (level - 1)

func split() -> void:
	if level == max_level: 
		return
	var number_of_skill_drop_per_child: int = ceil(float(number_of_skill_drop) / float(number_per_split))
	print("number: " + str(number_of_skill_drop_per_child))
	for i in number_per_split:
		#randomize()
		var son = (load(self.scene_file_path) as PackedScene).instantiate()
		if son != null and son is Mushroom:
			(son as Mushroom)._ready()
			var dir: int = randi_range(0, 1)
			dir = dir * 2 - 1
			(son as Mushroom).change_direction(dir)
			#var distance: float = randf_range(split_min_distance, split_max_distance)
			(son as Mushroom).position.x = position.x + direction * 0
			(son as Mushroom).position.y = position.y
			(son as Mushroom).elemental_type = elemental_type
			(son as Mushroom).max_level = max_level
			(son as Mushroom).level = level + 1
			(son as Mushroom).max_scale = max_scale
			if number_of_skill_drop_per_child < number_of_skill_drop:
				number_of_skill_drop -= number_of_skill_drop_per_child
				(son as Mushroom).number_of_skill_drop = number_of_skill_drop_per_child
			else:
				(son as Mushroom).number_of_skill_drop = number_of_skill_drop
				number_of_skill_drop = 0
			(son as Mushroom)._ready()
			get_tree().root.add_child(son)
			#GameManager.current_stage.find_child("Enemies").add_child(son)
