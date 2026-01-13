class_name Player extends CharacterBody3D


@export var speed := 5.0
@export var turn_speed := 1.5
@export var jump_velocity: Vector3 = Vector3(0, 4.5, 0)

@onready var sync_pos: Vector3 = global_position
@onready var sync_rot: Vector3 = global_rotation_degrees


@onready var _camera: Camera3D = %Camera3D
# @onready var _camera_pivot: Node3D = %CameraPivot


var rot_amt: Vector3 = Vector3.ZERO
var movement_amt: Vector3 = Vector3.ZERO


func _ready():
	$MultiplayerSynchronizer.set_multiplayer_authority(name.to_int())

	_camera.clear_current()
	if $MultiplayerSynchronizer.get_multiplayer_authority() == multiplayer.get_unique_id():
		_camera.make_current()

	global_position = sync_pos
	global_rotation_degrees = sync_rot

func update_sync_values():
	sync_pos = global_position
	sync_rot = global_rotation_degrees


func _physics_process(delta: float) -> void:
	if $MultiplayerSynchronizer.get_multiplayer_authority() == multiplayer.get_unique_id():

		# Add the gravity.
		if not is_on_floor():
			velocity += get_gravity() * delta

		move_and_slide()
		update_sync_values()

	if not movement_amt:
		velocity.x = move_toward(velocity.x, 0, speed)
		velocity.z = move_toward(velocity.z, 0, speed)
	else:
		velocity.x = movement_amt.x
		velocity.z = movement_amt.z

	if rot_amt:
		rotate(Vector3.UP, rot_amt.x * delta * turn_speed)
	# else: # TODO: figure this out
	# 	global_position = global_position.move_toward(sync_pos, delta * speed)
	# 	global_rotation_degrees = global_rotation_degrees.move_toward(sync_rot, delta * speed)

func set_color(color: Color) -> void:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	$MeshInstance3D.material_override = mat

func _unhandled_input(event: InputEvent) -> void:
	# Handle jump.
	if Input.is_action_just_pressed(&"jump") and is_on_floor():
		velocity.y = jump_velocity.y

	# Get the input direction and handle the movement_amt/deceleration.
	# As good practice, you should replace UI actions with custom gameplay actions.
	# var input_dir := Input.get_vector(&"move_left", &"move_right", &"move_forward", &"move_backward")
	var hor := Input.get_axis(&"move_left", &"move_right")
	var ver := Input.get_axis(&"move_forward", &"move_backward")

	if hor:
		rot_amt.x = -hor

	var direction := (transform.basis * Vector3(0, 0, ver)).normalized()
	if direction:
		movement_amt.x = direction.x * speed
		movement_amt.z = direction.z * speed
