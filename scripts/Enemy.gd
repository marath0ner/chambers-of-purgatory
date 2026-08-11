extends CharacterBody3D
const SPEED = 5
@onready var health : int = 100
@export var loot_scene : PackedScene
@export var loot_table : LootTable
@onready var animation_player: AnimationPlayer = $fat_rattus/AnimationPlayer
@onready var fat_rattus: Node3D = $fat_rattus
@onready var player_character: CharacterBody3D = %CharacterBody3D
@onready var target_pos : Vector3
@onready var navigation_agent_3d: NavigationAgent3D = $NavigationAgent3D
@onready var rat_hurt_sfx: AudioStreamPlayer3D = $RatHurtSFX
@onready var rat_death_sfx: AudioStreamPlayer3D = $RatDeathSFX
@onready var audio_manager: Node3D = %AudioManager
@onready var rat_walk_sfx: AudioStreamPlayer3D = $RatWalkSFX
@onready var rat_idle_sfx: AudioStreamPlayer3D = $RatIdleSFX
@onready var death_screen: CanvasLayer = $"../../DeathScreen"
@onready var rat_hurt_sfx_2: AudioStreamPlayer3D = $RatHurtSFX2
@onready var ray_cast_3d: RayCast3D = $RayCast3D
@onready var health_bar: TextureProgressBar = $SubViewport/HealthBar
@onready var enemy_ui: Sprite3D = $EnemyUI

enum State { IDLE, CHASE }
var knockback := Vector3.ZERO
var direction : Vector3
var is_colliding := false
var current_state = State
var player_in_range : bool = false

func _ready() -> void:
	current_state = State.IDLE

func _physics_process(delta : float):
	match current_state:
		State.IDLE:
			direction = Vector3.ZERO
			animation_player.play("Idle", 5)
			rat_walk_sfx.stop()
			enemy_ui.hide()
		State.CHASE:
			target_pos = player_character.global_position
			navigation_agent_3d.target_position = target_pos
			animation_player.play("Chase", 5)
			if !rat_walk_sfx.playing:
				rat_walk_sfx.play()

		# Gets the next point along the path to the player
			var next_pos = navigation_agent_3d.get_next_path_position()
	
		# Get the direction to the next path point, smoothly adjust rotation
			var desired_direction = (next_pos - global_position).normalized()
			var desired_rotation = atan2(-desired_direction.x, -desired_direction.z)
			direction = direction.lerp(desired_direction, 5.0 * delta)
			rotation.y = lerp_angle(rotation.y, desired_rotation, 5.0 * delta)

	ray_cast_3d.target_position = ray_cast_3d.to_local(player_character.global_position)
	ray_cast_3d.force_raycast_update()
	try_chase()
	
	if health <= 0:
		
		die()
	# Apply gravity
	if not is_on_floor():
		velocity += get_gravity() * delta
	
	if death_screen.visible == true:
		rat_walk_sfx.stop()
	
	var move_velocity = direction * SPEED
	knockback = knockback.lerp(Vector3.ZERO, 6.0 * delta)
	velocity.x = move_velocity.x + knockback.x
	velocity.z = move_velocity.z + knockback.z
	if Input.is_action_just_pressed("Restart"):
		player_in_range = false
		current_state = State.IDLE
	move_and_slide()
	
func take_damage(damage : int, force : Vector3) -> void:
	var tween = create_tween()
	
	health -= damage
	
	tween.tween_property(health_bar, "value", health, 0.2)
	
	if health > 0:
		knockback = force
	print("I took ", damage, " damage. I have ", health, " HP.")
	
	rat_hurt_sfx.play()
	rat_hurt_sfx_2.play()

func die():
	rat_death_sfx.reparent(%AudioManager)
	rat_death_sfx.play(.39)
	print("TN died.")
	drop_loot()
	queue_free()
	# NEXT UP: ADD LOOTSTUFFS. WHEN ENEMY DIES, CALL GLOBAL LOOT SCRIPT. ROLL AN ITEM THEN DROP IT ON DEATH

func drop_loot():
	var loot_instance = loot_scene.instantiate()
	var rolled_loot = loot_table.roll_loot()
	
	if rolled_loot:
		loot_instance.loot_data = rolled_loot
		loot_instance.global_position = global_position + Vector3(0,0.5,0)
		get_tree().current_scene.add_child(loot_instance)
		print(rolled_loot.name, "\n", rolled_loot.Rarity.find_key(rolled_loot.rarity), " ", rolled_loot.Type.find_key(rolled_loot.type), "\n", rolled_loot.description)

func _on_hitbox_body_entered(body: Node3D) -> void:
	if body.is_in_group("Player"):
		is_colliding = true
		var player = body
		while is_colliding:
			await get_tree().create_timer(0.7).timeout
			if is_colliding:
				print("I chomp again")
				player.take_damage(8.0)

func _on_hitbox_body_exited(body: Node3D) -> void:
	if body.is_in_group("Player"):
		print("Player left")
		is_colliding = false

func _on_detection_area_body_entered(body: Node3D) -> void:
	if body.is_in_group("Player"):
		player_in_range = true
		
func _on_detection_area_body_exited(body: Node3D) -> void:
	if body.is_in_group("Player"):
		player_in_range = false
		rat_walk_sfx.stop()
		current_state = State.IDLE

func try_chase():
	if player_in_range:
		if !ray_cast_3d.is_colliding():
			if current_state != State.CHASE:
				current_state = State.CHASE
				show_enemy_ui()
				rat_idle_sfx.play()

func show_enemy_ui():
	var tween = create_tween()
	enemy_ui.show()
	enemy_ui.transparency = 1.0
	
	tween.tween_property(enemy_ui, "transparency", 0.0, 1)
