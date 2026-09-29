extends AnimatableBody3D
@onready var animation_player: AnimationPlayer = $AnimationPlayer
var activated := false

func _physics_process(delta: float) -> void:
	if !activated:
		if Input.is_action_just_pressed("TestAction"):
			animation_player.play("rise")
			activated = true
