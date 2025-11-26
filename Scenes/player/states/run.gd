extends PlayerState

@onready var walk_fx_factory: Node2DFactory = $"../../Direction/WalkFXFactory"
@export var dist_between_walk_fx: float = 50
@export var cur_walk_dist: float = 0

@onready var walk_sfx_player: AudioStreamPlayer2D = null

func _enter() -> void:
	#Change animation to run
	obj.change_animation("run")
	obj.walk_sfx_player.play()
	timer = 0.2
	pass

func _update(_delta: float):
	if update_timer(_delta):
		var walk_fx = walk_fx_factory.create() as Node2D
		#print(obj.scale)
		walk_fx.scale.x = obj.direction
		timer = 0.2
	
	control_attack()
	
	control_throw_blade()
	
	#Control jump
	control_jump()
	
	control_dash()
	
	#Control moving and if not moving change to idle
	if not control_moving():
		change_state(fsm.states.idle)
		
	#If not on floor change to fall
	if not obj.is_on_floor():
		change_state(fsm.states.fall)
