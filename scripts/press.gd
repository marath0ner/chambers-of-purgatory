extends Node3D
class_name RatPress
@onready var collision_shape_3d: CollisionShape3D = $MeshInstance3D/Area3D/CollisionShape3D

signal enemy_squished

var starting_pos : Vector3
var offset := Vector3(0, -11.0, 0)
var is_slamming := false

func _ready() -> void:
	collision_shape_3d.disabled = true

func _physics_process(_delta: float) -> void:
	slam()

func slam():
	if is_slamming: return
	
	is_slamming = true
	starting_pos = self.global_position
	var tween := create_tween()
	
	tween.tween_callback(func(): collision_shape_3d.disabled = false)
	
	tween.tween_property(self, "global_position", starting_pos + offset, .25)\
		.set_trans(Tween.TRANS_QUAD)\
		.set_ease(Tween.EASE_IN)
	
	tween.tween_callback(func(): collision_shape_3d.disabled = true)
	tween.tween_interval(1)
	
	tween.tween_property(self, "global_position", starting_pos, 2)\
		.set_trans(Tween.TRANS_QUAD)\
		.set_ease(Tween.EASE_OUT)
	
	tween.tween_interval(1)
	await tween.finished
	is_slamming = false


func _on_area_3d_body_entered(body: Node3D) -> void:
	if body.is_in_group("Player"):
		body.take_damage(1000)
	
	if body.is_in_group("Enemy"):
		body.take_damage(1000, Vector3.ZERO)
		enemy_squished.emit()
		
