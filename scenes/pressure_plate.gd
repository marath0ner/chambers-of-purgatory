extends Node3D
class_name PressurePlate
@onready var audio_stream_player_3d: AudioStreamPlayer3D = $AudioStreamPlayer3D

var offset := Vector3(0, -.15, 0)
var starting_pos : Vector3
var inactive := true

func activate():
	if inactive:
		inactive = false
		var tween := create_tween()
		starting_pos = self.global_position
		tween.tween_property(self, "global_position", starting_pos + offset, .8)
		audio_stream_player_3d.play()
		provoke_ratti()

func provoke_ratti():
	var rattuses = get_tree().get_nodes_in_group("TrapRatti")
	for rat in rattuses:
		rat.change_state(Rattus.State.CHASE)
