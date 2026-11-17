extends CharacterBody3D
## اللاعب: حركة WASD + نظرة الماوس + إحصاءات البقاء (الصحة والماء).

signal health_changed(value: float, max_value: float)
signal water_changed(value: float, max_value: float)
signal died

const MAX_HEALTH := 100.0
const MAX_WATER := 100.0
const DEHYDRATION_DAMAGE_PER_SECOND := 5.0
const MOVE_SPEED := 4.0
const JUMP_SPEED := 4.5
const MOUSE_SENSITIVITY := 0.0025
const GRAVITY := 12.0

var health := MAX_HEALTH
var water := MAX_WATER
var spawn_point := Vector3.ZERO

@onready var head: Node3D = $Head
@onready var camera: Camera3D = $Head/Camera3D

func _ready() -> void:
	spawn_point = global_position
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	health_changed.emit(health, MAX_HEALTH)
	water_changed.emit(water, MAX_WATER)

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		rotate_y(-event.relative.x * MOUSE_SENSITIVITY)
		head.rotate_x(-event.relative.y * MOUSE_SENSITIVITY)
		head.rotation.x = clampf(head.rotation.x, -PI / 2.0, PI / 2.0)
	elif event.is_action_pressed("ui_cancel"):
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	elif event is InputEventMouseButton and event.pressed and Input.mouse_mode != Input.MOUSE_MODE_CAPTURED:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity.y -= GRAVITY * delta
	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = JUMP_SPEED
	var input_dir := Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	var direction := (transform.basis * Vector3(input_dir.x, 0.0, input_dir.y)).normalized()
	velocity.x = direction.x * MOVE_SPEED
	velocity.z = direction.z * MOVE_SPEED
	move_and_slide()
	_update_survival(delta)

func _update_survival(delta: float) -> void:
	if water <= 0.0:
		take_damage(DEHYDRATION_DAMAGE_PER_SECOND * delta)

func take_damage(amount: float) -> void:
	var was_alive := health > 0.0
	health = maxf(health - amount, 0.0)
	health_changed.emit(health, MAX_HEALTH)
	if was_alive and health <= 0.0:
		died.emit()
		respawn()

func drink(amount: float) -> void:
	water = clampf(water + amount, 0.0, MAX_WATER)
	water_changed.emit(water, MAX_WATER)

func use_water(amount: float) -> void:
	water = maxf(water - amount, 0.0)
	water_changed.emit(water, MAX_WATER)

func respawn() -> void:
	global_position = spawn_point
	velocity = Vector3.ZERO
	health = MAX_HEALTH
	water = MAX_WATER
	health_changed.emit(health, MAX_HEALTH)
	water_changed.emit(water, MAX_WATER)
