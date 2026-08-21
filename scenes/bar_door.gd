extends Node3D
@onready var press: RatPress = $"../press"

var starting_pos : Vector3
var offset := Vector3(0, 11.0, 0)
var is_open := false

func _ready() -> void:
	press.enemy_squished.connect(open_door)
	
func open_door():
	if is_open: return
	
	is_open = true
	starting_pos = self.global_position
	var tween := create_tween()
	tween.tween_property(self, "global_position", starting_pos + offset, 1.1)\
		.set_trans(Tween.TRANS_QUAD)\
		.set_ease(Tween.EASE_IN)
