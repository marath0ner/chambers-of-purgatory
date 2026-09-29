extends Control
class_name Inventory
@onready var AcquiredLoot : Array[Loot] = []
@onready var v_box_container: VBoxContainer = $VBoxContainer

func add_item(item : Loot):
	AcquiredLoot.append(item)
	var item_label := Label.new()
	item_label.text = str(item.name)
	item_label.name = item.name
	v_box_container.add_child(item_label)

func remove_item(item_name : String):
	for item in AcquiredLoot:
		if item.name == item_name:
			AcquiredLoot.erase(item)
			
			var item_label = v_box_container.get_node_or_null(item_name)
			if item_label:
				item_label.queue_free()
	
	# TODO: REVIEW!!!!!!!!!!

func has(item_name : String) -> bool:
	for n in AcquiredLoot:
		if item_name == n.name:
			return true
	return false

func display_inventory():
	self.show()
