extends PlayerState

func _enter() -> void:
	#Change animation to fall
	obj.change_animation("fall")
	pass

func _update(_delta: float) -> void:
	#Control moving
	var is_moving: bool = control_moving()
	
	control_dash()
	
	control_jump_attack()
	
	control_throw_blade()
	
	obj.is_right()
	
	if obj.is_on_wall() and is_moving and !obj.is_in_fireball_state:
		if !is_wall_layer(9): 
			change_state(fsm.states.wallcling)
		else:
			pass
	
	#If on floor change to idle if not moving and not jumping
	if obj.is_on_floor() and not is_moving:
		change_state(fsm.states.idle)
	pass
	
# Hàm kiểm tra layer của tường
func is_wall_layer(target_layer_int: int) -> bool:
	for i in obj.get_slide_collision_count():
		var collision = obj.get_slide_collision(i)
		
		# 1. Kiểm tra xem có phải là tường không (dựa vào vector pháp tuyến)
		if abs(collision.get_normal().x) > 0.5:
			var collider = collision.get_collider()
			
			# 2. Kiểm tra Layer
			# CÁCH 1: Dành cho Godot 4 (Dễ đọc nhất)
			if collider.has_method("get_collision_layer_value"):
				if collider.get_collision_layer_value(target_layer_int):
					return true
			
			# CÁCH 2: Dành cho Godot 3 hoặc check thủ công (Bitwise)
			# Tính giá trị bit: 1 dịch sang trái (layer - 1) lần
			# Ví dụ Layer 9: 1 << 8 = 256
			elif "collision_layer" in collider:
				var layer_bit = 1 << (target_layer_int - 1)
				if int(collider.collision_layer) & layer_bit:
					return true
					
	return false
