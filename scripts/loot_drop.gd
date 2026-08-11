extends Node3D
class_name LootDrop

@onready var loot_drop: LootDrop = $"."
@onready var label_3d: Label3D = $Details/Label3D
@onready var drop_sfx: AudioStreamPlayer3D = $DropSFX
@onready var interact_prompt: Control = $InteractPrompt

@export var loot_data : Loot
var loot_mesh : PackedScene
var mesh_instance : Node3D
var time : float = 0.0
var speed : float = 1.25
var amplitude : float = .1
var base_y : float
var player_in_range := false
var current_player : CharacterBody3D = null

func _ready() -> void:
	if loot_data:
		drop_sfx.play()
		label_3d.text = str(loot_data.name, "\n", loot_data.Rarity.find_key(loot_data.rarity), " ", loot_data.Type.find_key(loot_data.type), "\n", loot_data.description)
		loot_mesh = loot_data.model
		# HACK: review
	if loot_mesh:
		
		mesh_instance = loot_mesh.instantiate()
		loot_drop.add_child(mesh_instance)
		base_y = mesh_instance.position.y
	
func _process(delta: float) -> void:
	if mesh_instance:
		time += delta
		mesh_instance.rotate_y(delta * 2.0)
		mesh_instance.position.y = base_y + sin(time * speed) * amplitude
	
	if player_in_range and Input.is_action_just_pressed("Interact"):
		pickup()
		current_player.pickup_item(loot_data)
	
func _on_area_3d_body_entered(body: Node3D) -> void:
	if body.is_in_group("Player"):
		player_in_range = true
		current_player = body
		interact_prompt.show()

func _on_area_3d_body_exited(body: Node3D) -> void:
	if body.is_in_group("Player"):
		player_in_range = false
		current_player = null
		interact_prompt.hide()

func pickup():
	
	# HACK pass weapon data and mesh to player script to make an equippable item instance
	queue_free()
	
# ------------------------------------------------------------------------------------------------
# TODO:
# FIRST: Add UI that shows item details when hovering
# SECOND: Make item drops equipable/pickupable, press E to pickup/equip, queue_free the LootDrop
# Add loot tables with weighted chance
# ------------------------------------------------------------------------------------------------
