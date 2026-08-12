extends Control
class_name Inventory
@onready var AcquiredLoot : Array[Loot] = []
@onready var v_box_container: VBoxContainer = $VBoxContainer

func add_item(item : Loot):
	AcquiredLoot.append(item)
	
	var item_label := Label.new()
	item_label.text = str(item.name)
	v_box_container.add_child(item_label)


func display_inventory():
	self.show()
