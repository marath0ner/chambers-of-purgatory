extends PressurePlate
@onready var animation_player: AnimationPlayer = $"../AnimationPlayer"


func victory_check(can_win : bool):
	if can_win:
		animation_player.play("rise")
		self.activate()
		print("you win")
	else:
		print("needs a key")
