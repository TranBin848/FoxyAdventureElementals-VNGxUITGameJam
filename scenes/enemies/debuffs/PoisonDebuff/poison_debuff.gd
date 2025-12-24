extends Debuff

@export var poison_start_time: float = 0.8
@export var poison_perform_time: float = 2.4
@export var poison_end_time: float = 0.5

@export var elemental_type: ElementsEnum.Elements = ElementsEnum.Elements.WOOD
@export var damage: int = 3
@export var damage_interval: float = 0.3

var damage_timer: float = 0

func _init_default_time_values() -> void:
	start_time = poison_start_time
	perform_time = poison_perform_time
	end_time = poison_end_time

func perform_state_start() -> void:
	damage_timer = damage_interval

func perform_state_update(delta: float) -> void:
	damage_timer -= delta
	if damage_timer <= 0:
		target._on_hurt_area_2d_hurt(Vector2.ZERO, damage, elemental_type)
		damage_timer = damage_interval
	super.perform_state_update(delta)

func end_state_exit() -> void:
	if target != null: target.freeze_in_place(false)
	super.end_state_exit()
