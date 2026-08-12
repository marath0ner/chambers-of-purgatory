extends Node3D
class_name PressurePlate

var offset := Vector3(0, -.15, 0)
var starting_pos : Vector3
var inactive := true

func activate():
	if inactive:
		inactive = false
		var tween := create_tween()
		starting_pos = self.global_position
		tween.tween_property(self, "global_position", starting_pos + offset, .8)

# TODO: make this emit a signal that traps the player in the room and provokes all of the rattuses
