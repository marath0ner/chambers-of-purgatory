extends Node3D
@onready var treasure_chest: Node3D = $treasure_chest
@onready var animation_player: AnimationPlayer = $treasure_chest/AnimationPlayer
@onready var audio_stream_player_3d: AudioStreamPlayer3D = $treasure_chest/AudioStreamPlayer3D
@export var loot_scene : PackedScene
@export var loot_table : LootTable
@onready var control: Control = $Control
@onready var label: Label = $Control/Label
@onready var inventory: Inventory = $"../CharacterBody3D/Bars/Inventory"



var locked := true
var opened := false
var player_in_range := false
var current_player : CharacterBody3D = null

func _process(delta: float) -> void:
	if !locked:
		label.text = "Press [E] to open"
		if !opened:
			if player_in_range:
				if Input.is_action_just_pressed("Interact"):
					opened = true
					control.hide()
					audio_stream_player_3d.play()
					animation_player.play("chest_open")
					roll_loot()
	else:
		label.text = "It's locked"

	if Input.is_action_just_pressed("Interact"):
		if player_in_range and locked:
			if inventory.has("Key"):
				inventory.remove_item("Key")
				locked = false

func roll_loot():
	var loot_instance = loot_scene.instantiate()
	var rolled_loot = loot_table.roll_loot()
	
	if rolled_loot:
		loot_instance.loot_data = rolled_loot
		loot_instance.global_position = global_position + Vector3(0,0.5,-1)
		get_tree().current_scene.add_child(loot_instance)

# TODO: make the chest locked until the encounter is completed, then drop a random item

func _on_area_3d_body_entered(body: Node3D) -> void:
	if !opened:
		if body.is_in_group("Player"):
			player_in_range = true
			current_player = body
			control.show()

func _on_area_3d_body_exited(body: Node3D) -> void:
	if body.is_in_group("Player"):
		player_in_range = false
		current_player = null
		control.hide()
