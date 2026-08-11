extends Label
func _process(delta: float) -> void:
	text = ""
	text += "FPS: " + str(Engine.get_frames_per_second())
