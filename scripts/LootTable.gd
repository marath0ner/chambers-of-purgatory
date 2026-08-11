extends Resource
class_name LootTable

@export var name : String
@export var table : Dictionary[Loot, int] = {}


func roll_loot() -> Loot:
	var total_weights : int = 0
	for loot in table:
		total_weights += table[loot]
		print(total_weights)
	var roll := randi_range(0, total_weights)
	var cumulative : int = 0
	print("Roll is ", roll, " out of ", total_weights)
	for loot in table:
		cumulative += table[loot]
		if roll <= cumulative:
			return loot
	
	return null
