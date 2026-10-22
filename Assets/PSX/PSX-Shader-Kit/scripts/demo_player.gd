extends CharacterBody3D

@export var walk_speed: float = 3.0
@export var sprint_speed: float = 5.0
@export var mouse_sensitivity: float = 0.002
@onready var camera: Camera3D = $Camera3D
@onready var flashlight: SpotLight3D = $Camera3D/Flashlight
var spawn_transform: Transform3D

func _ready() -> void:
	spawn_transform = global_transform
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT:
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	elif event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	elif event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		rotate_y(-event.screen_relative.x * mouse_sensitivity)
		camera.rotation.x = clampf(camera.rotation.x - event.screen_relative.y * mouse_sensitivity, -1.4, 1.4)
	elif event.is_action_pressed("flashlight"):
		flashlight.visible = not flashlight.visible
	elif event.is_action_pressed("reset_view"):
		reset_view()

func reset_view() -> void:
	global_transform = spawn_transform
	camera.rotation = Vector3.ZERO
	velocity = Vector3.ZERO
	reset_physics_interpolation()

func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity.y -= 9.8 * delta
	var direction := Vector3.ZERO
	if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		var axis := Input.get_vector("move_left", "move_right", "move_forward", "move_back")
		direction = global_basis * Vector3(axis.x, 0.0, axis.y)
	var speed := sprint_speed if Input.is_action_pressed("sprint") else walk_speed
	velocity.x = direction.x * speed
	velocity.z = direction.z * speed
	move_and_slide()
	if global_position.y < -4.0:
		reset_view()
