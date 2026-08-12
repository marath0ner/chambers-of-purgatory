extends Camera3D

@export var period = 0.2
@export var magnitude = 0.01
var initial_rotation = self.rotation
func _camera_shake():
	
	var elapsed_time = 0.0

	while elapsed_time < period:
		var offset = Vector3(
			randf_range(-magnitude, magnitude),
			randf_range(-magnitude, magnitude),
			randf_range(-magnitude, magnitude)
		)

		self.rotation = initial_rotation + offset
		elapsed_time += get_process_delta_time()
		if is_inside_tree():
			await get_tree().process_frame
	self.rotation = initial_rotation
