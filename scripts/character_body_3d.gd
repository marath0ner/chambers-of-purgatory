extends CharacterBody3D
@onready var camera_3d: Camera3D = %Camera3D
@onready var hitbox: Area3D = %Hitbox
@onready var player_weapon: WeaponClass = %PlayerWeapon
@onready var camera_rig: Node3D = $CameraRig
@onready var mesh_instance_3d: MeshInstance3D = $MeshInstance3D
@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var health_bar: ColorRect = $Bars/Control/HealthBar
@onready var stamina_bar: ColorRect = $Bars/Control/StaminaBar
@onready var damage_indicator: ColorRect = %DamageIndicator
@onready var walk_sfx: AudioStreamPlayer3D = $WalkSFX
@onready var weapon_sfx: AudioStreamPlayer3D = $CameraRig/PlayerWeapon/WeaponSFX
@export var can_chain := false
@onready var weapon_particles: GPUParticles3D = $CameraRig/PlayerWeapon/WeaponParticles
@onready var death_screen: CanvasLayer = $"../DeathScreen"
@onready var pickup_sfx: AudioStreamPlayer3D = $AudioManager/PickupSFX
@onready var bars: CanvasLayer = %Bars
@onready var debug_text: Label = $Bars/Control/DebugText
@onready var debug_text_2: Label = $Bars/Control/DebugText2
@onready var inventory: Inventory = $Bars/Inventory
@onready var sword_slice_sfx: AudioStreamPlayer3D = $AudioManager/SwordSliceSFX
@onready var player_hurt_sfx: AudioStreamPlayer3D = $AudioManager/PlayerHurtSFX
@onready var pressure_plate: PressurePlate = $"../PressurePlate"


const SPEED = 5.0
const JUMP_VELOCITY = 4.5
const look_sens = .001
const SPRINT_SPEED = 7.0
const WALK_SPEED = 3.0
const STRAFE_SPEED = 3.0
const HEADBOB_MOVE_AMOUNT = 0.06
const HEADBOB_FREQUENCY = 2.4

enum State { IDLE, WALKING, SPRINTING, JUMPING, FALLING }

var headbob_time := 0.0
var health : float = 100.0
var max_health : float = 100.0
var current_weapon : PackedScene
var paused := false
var can_attack := true
var weapon_damage
var stamina : float = 100.0
var max_stamina : float = 1000.0 # default 100
var stamina_just_used : bool = false
var stamina_regen_rate : float = 50.0 # default 25
var stamina_regen_timer : SceneTreeTimer = null
var is_walking := false
var hit_number := 0
var queued_attack := false
var is_attacking := false
var waiting_for_animation_finish := false
var can_sprint := true
var current_state = State

func _ready() -> void:
	hitbox.monitoring = true
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	mesh_instance_3d.set_layer_mask_value(1, false)
	mesh_instance_3d.set_layer_mask_value(2, true)
	weapon_damage = %PlayerWeapon.weapon_damage
	current_state = State.IDLE
	debug_text.text = str(%Camera3D.transform.origin)
	debug_text_2.text = str(current_state)
	inventory.add_item(player_weapon.weapon_data)
	
func _physics_process(delta: float) -> void:
	# Add the gravity.
	if not is_on_floor():
		velocity += get_gravity() * delta
		is_walking = false

	# Handle jump.
	if Input.is_action_just_pressed("Jump") and is_on_floor():
		velocity.y = JUMP_VELOCITY
	
	if (Input.is_action_just_pressed("Attack")) or (Input.is_action_pressed("Attack")):
		if is_attacking:
			if can_chain:
				if stamina > 0:
					queued_attack = true
		else:
			start_attack()
	
	if health <= 0:
		death_screen.show()
		%Bars.hide()
		player_weapon.hide()
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		Engine.time_scale = 0.05
		if Input.is_action_just_pressed("Restart"):
			Engine.time_scale = 1
			get_tree().reload_current_scene()
	
	health_bar.size.x = clamp(lerp(health_bar.size.x, health*2, .1), 0, max_health*2)
	
	if stamina < max_stamina:
		if can_attack == true:
			if stamina_just_used == false:
				var regened_stamina = stamina_regen_rate * delta
				stamina += regened_stamina
				stamina = min(stamina, max_stamina)
	stamina_bar.size.x = clamp(lerp(stamina_bar.size.x, stamina*2, .1), 0, max_stamina*2)
	
	
	_handle_ground_physics()
	_headbob_effect(delta)
	if Input.is_action_just_pressed("Inventory"):
		if inventory.visible:
			inventory.hide()
		elif inventory.hidden:
			inventory.display_inventory()
	debug_text.text = str(player_weapon.weapon_name)
	match current_state:
		State.IDLE:
			debug_text_2.text = "IDLE"
		State.WALKING:
			debug_text_2.text = "WALKING"
		State.SPRINTING:
			debug_text_2.text = "SPRINTING"
	_walking_sfx_manager()
	move_and_slide()

func _unhandled_input(event: InputEvent) -> void:
	if Input.is_action_just_pressed("ui_cancel"):
		paused = !paused
		if paused:
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		else:
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	

		
	
	if event is InputEventMouseMotion:
		rotate_y(-event.relative.x * look_sens)
		$CameraRig.rotate_x(-event.relative.y * look_sens)
		$CameraRig.rotation.x = clamp($CameraRig.rotation.x, deg_to_rad(-90), deg_to_rad(90))

func _headbob_effect(delta):
	var target_position : Vector3
	var idle_position := Vector3.ZERO
	if current_state == State.WALKING or current_state == State.SPRINTING:
		headbob_time += delta * velocity.length()
		target_position = Vector3(
			cos(headbob_time * HEADBOB_FREQUENCY * 0.5) * HEADBOB_MOVE_AMOUNT,
			sin(headbob_time * HEADBOB_FREQUENCY) * HEADBOB_MOVE_AMOUNT,
			0
		)
		%Camera3D.transform.origin = lerp(%Camera3D.transform.origin, target_position, 10*delta)
	elif current_state == State.IDLE:
		headbob_time = lerp(headbob_time, 0.0, 0.8)
		%Camera3D.transform.origin = lerp(%Camera3D.transform.origin, idle_position, 2*delta)

func _walking_sfx_manager():
	if is_walking:
		if !walk_sfx.playing:
			walk_sfx.play()
	else:
		if walk_sfx.playing:
			await walk_sfx.finished
			walk_sfx.stop()

func start_attack():
	if stamina <= 0:
		return
	
	is_attacking = true
	hit_number = 1
	queued_attack = false
	
	animation_player.play("ComboHit1")
	adjust_stamina(weapon_damage) 

func take_damage(damage : float) -> void:
	health -= damage
	player_hurt_sfx.play()
	damage_indicator.fade_out()

func try_combo():
	if queued_attack and hit_number == 1 and stamina > 0:
		queued_attack = false
		hit_number = 2
		adjust_stamina(weapon_damage)
		animation_player.play("ComboHit2")
	elif queued_attack and hit_number == 2 and stamina > 0:
		queued_attack = false
		hit_number = 3
		adjust_stamina(weapon_damage)
		animation_player.play("ComboHit3")
	if waiting_for_animation_finish == false:
		waiting_for_animation_finish = true
		await animation_player.animation_finished
		reset_combo()

func reset_combo():
	is_attacking = false
	hit_number = 0
	queued_attack = false
	animation_player.play("WeaponIdle")

func hitstop(duration : float):
	Engine.time_scale = 0.01
	await get_tree().create_timer(duration, true, false, true).timeout
	Engine.time_scale = 1.0

func adjust_stamina(amount : float):
	stamina -= amount
	stamina = max(stamina, 0)
	var changed_amount = stamina
	stamina_bar.size.x = clamp(lerp(stamina_bar.size.x, changed_amount*2, .1), 0, max_stamina*2)
	stamina_just_used = true
	# Cancel previous timer
	if stamina_regen_timer:
		stamina_regen_timer.disconnect("timeout", Callable(self, "_on_stamina_regen_timeout"))

	# Start new timer
	stamina_regen_timer = get_tree().create_timer(2.0)
	stamina_regen_timer.timeout.connect(_on_stamina_regen_timeout)

func _on_stamina_regen_timeout():
	stamina_just_used = false

func pickup_item(item: Loot):
	pickup_sfx.play()
	print("I got a ", item.name)
	inventory.add_item(item)
	if item.type == Loot.Type.WEAPON:
		player_weapon.weapon_data = item
		player_weapon.load_weapon()
		weapon_damage = item.attack_damage

func _on_hitbox_area_entered(area: Area3D) -> void:
	if area.is_in_group("Enemy"):
		var enemy = area.get_parent()
		sword_slice_sfx.play()
		if enemy.has_method("take_damage"):
			weapon_particles.restart()
			%Camera3D._camera_shake()
			hitstop(0.2)
			var dir = (enemy.global_position - global_position).normalized()
			if hit_number == 3:
				enemy.take_damage(weapon_damage*1.5, dir * 72)
				print("CRITICAL HIT!!!")
			else:
				enemy.take_damage(weapon_damage, dir * 48)

func _handle_ground_physics():
	var input_dir := Input.get_vector("Left", "Right", "Forward", "Backward")
	var direction := (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	
	if direction:
		if Input.is_action_pressed("Forward"):
			velocity.x = direction.x * WALK_SPEED
			velocity.z = direction.z * WALK_SPEED
			if is_on_floor():
				is_walking = true
				current_state = State.WALKING
			if Input.is_action_pressed("Sprint"):
				if stamina > 0:
					current_state = State.SPRINTING
					walk_sfx.pitch_scale = 1.2
					velocity.x = direction.x * SPRINT_SPEED
					velocity.z = direction.z * SPRINT_SPEED
					adjust_stamina(.5)
					
				else:
					walk_sfx.pitch_scale = 0.8
			else:
				walk_sfx.pitch_scale = 0.8
			if Input.is_action_just_pressed("Backward"):
				velocity.x = move_toward(velocity.x, 0, WALK_SPEED)
				velocity.z = move_toward(velocity.z, 0, WALK_SPEED)
				is_walking = false
				current_state = State.IDLE
		if Input.is_action_pressed("Left"):
			velocity.x = direction.x * STRAFE_SPEED
			velocity.z = direction.z * STRAFE_SPEED
			if is_on_floor():
				is_walking = true
				current_state = State.WALKING
		if Input.is_action_pressed("Right"):
			velocity.x = direction.x * STRAFE_SPEED
			velocity.z = direction.z * STRAFE_SPEED
			if is_on_floor():
				is_walking = true
				current_state = State.WALKING
		if Input.is_action_pressed("Backward"):
			velocity.x = direction.x * STRAFE_SPEED
			velocity.z = direction.z * STRAFE_SPEED
			if is_on_floor():
				is_walking = true
				current_state = State.WALKING
	else:
		is_walking = false
		velocity.x = move_toward(velocity.x, 0, 0.08)
		velocity.z = move_toward(velocity.z, 0, 0.08)
		current_state = State.IDLE

func _on_killzone_body_entered(body: Node3D) -> void:
	if body.is_in_group("Player"):
		take_damage(1000)


func _on_pressure_plate_body_entered(body: Node3D) -> void:
	pressure_plate.activate()
