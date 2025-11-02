extends PlayerState

@onready var walk_fx_factory: Node2DFactory = $"../../Direction/WalkFXFactory"
@export var dist_between_walk_fx: float = 50
@export var cur_walk_dist: float = 0

func _enter() -> void:
	#Change animation to run
	obj.change_animation("run")
	timer = 0.2
	pass

func _update(_delta: float):
	control_attack()
	
	control_throw_blade()
	
	if update_timer(_delta):
		var walk_fx = walk_fx_factory.create() as Node2D
		#print(obj.scale)
		walk_fx.scale.x = obj.direction
		timer = 0.2
	
	#Control jump
	control_jump()
	
	#Control moving and if not moving change to idle
	if not control_moving():
		change_state(fsm.states.idle)
		
	#If not on floor change to fall
	if not obj.is_on_floor():
		change_state(fsm.states.fall)
