extends ColorRect

var tween: Tween

func _ready():
	modulate.a = 0.0

func fade_out(duration: float = 1.0):
	# Stop any previous fade
	if tween and tween.is_running():
		tween.kill()

	show()

	tween = create_tween()
	modulate.a = duration
	tween.tween_property(self, "modulate:a", 0.0, 0.4)  # smooth fade out
	tween.tween_callback(hide)
