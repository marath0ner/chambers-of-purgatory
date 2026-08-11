@tool
extends Node3D
class_name WeaponClass



@export var weapon_data : Loot:
	set(value):
		weapon_data = value
		if Engine.is_editor_hint():
			load_weapon()
@export_category("Weapon Orientation")
@export var weapon_position : Vector3
@export var weapon_rotation : Vector3
@export_category("Visual Settings")
@export var weapon_mesh : PackedScene
var weapon_name : String
var weapon_damage : int
var instance : Node

func _ready() -> void:
	load_weapon()

func attack():
	pass

func load_weapon():
	if instance:
		instance.queue_free()
	if weapon_data:
		weapon_mesh = weapon_data.model
		position = weapon_position
		rotation_degrees = weapon_rotation
		weapon_name = weapon_data.name
		weapon_damage = weapon_data.attack_damage
		
		
	else:
		print("Nope")
	
	if weapon_mesh:
		instance = weapon_mesh.instantiate()
		add_child(instance)
