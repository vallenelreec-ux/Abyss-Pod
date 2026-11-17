extends CharacterBody3D
class_name PlayerCharacter
## اللاعب: حركة WASD بمحاذاة الشاشة (كاميرا إيزومترية ثابتة) + إحصاءات البقاء.

signal health_changed(value: float, max_value: float)
signal water_changed(value: float, max_value: float)
signal died
signal revived

const MAX_HEALTH := 100.0
const MAX_WATER := 100.0
const DEHYDRATION_DAMAGE_PER_SECOND := 5.0
const MOVE_SPEED := 4.0
const JUMP_SPEED := 4.5
const GRAVITY := 12.0
const PAID_REVIVE_HEALTH_RATIO := 0.5
const PAID_REVIVE_PROTECTION_SECONDS := 10.0

@export var zone_entrance_path: NodePath = NodePath("../ZoneEntrance")

var health := MAX_HEALTH
var water := MAX_WATER
var spawn_point := Vector3.ZERO
var is_dead := false
var protection_time_left := 0.0
## آخر اتجاه حركة أفقي، يستخدمه نظام الحفر لتحديد الجدار المستهدف.
var last_move_dir := Vector3(0, 0, -1)

@onready var inventory: Node = $Inventory

func _ready() -> void:
	spawn_point = global_position
	# التجهيز الابتدائي حسب GDD: فأس خشبي وقنينة ماء
	inventory.add_item("axe_wood")
	inventory.add_item("water_bottle")
	inventory.equip_item("axe_wood")
	health_changed.emit(health, MAX_HEALTH)
	water_changed.emit(water, MAX_WATER)

func _physics_process(delta: float) -> void:
	protection_time_left = maxf(protection_time_left - delta, 0.0)
	if is_dead:
		velocity = Vector3.ZERO
		return
	if not is_on_floor():
		velocity.y -= GRAVITY * delta
	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = JUMP_SPEED
	var input_dir := Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	var direction := _screen_aligned_direction(input_dir)
	if direction.length_squared() > 0.0:
		last_move_dir = direction
	velocity.x = direction.x * MOVE_SPEED
	velocity.z = direction.z * MOVE_SPEED
	move_and_slide()
	_update_survival(delta)

## يحوّل إدخال WASD إلى اتجاه في العالم بحسب زاوية الكاميرا الثابتة،
## فتطابق الأسهم على الشاشة حركة اللاعب مهما كانت زاوية الإيزومتري.
func _screen_aligned_direction(input_dir: Vector2) -> Vector3:
	var forward := Vector3(0, 0, -1)
	var right := Vector3(1, 0, 0)
	var cam := get_viewport().get_camera_3d()
	if cam != null:
		var cam_forward := -cam.global_transform.basis.z
		var cam_right := cam.global_transform.basis.x
		cam_forward.y = 0.0
		cam_right.y = 0.0
		if cam_forward.length_squared() > 0.0001:
			forward = cam_forward.normalized()
		if cam_right.length_squared() > 0.0001:
			right = cam_right.normalized()
	return right * input_dir.x + forward * -input_dir.y

func _update_survival(delta: float) -> void:
	if water <= 0.0:
		take_damage(DEHYDRATION_DAMAGE_PER_SECOND * delta)

func take_damage(amount: float) -> void:
	if is_dead:
		return
	var was_alive := health > 0.0
	health = maxf(health - amount, 0.0)
	health_changed.emit(health, MAX_HEALTH)
	if was_alive and health <= 0.0:
		is_dead = true
		velocity = Vector3.ZERO
		died.emit()

func drink(amount: float) -> void:
	water = clampf(water + amount, 0.0, MAX_WATER)
	water_changed.emit(water, MAX_WATER)

func use_water(amount: float) -> void:
	water = maxf(water - amount, 0.0)
	water_changed.emit(water, MAX_WATER)

func can_attack() -> bool:
	return not is_dead and protection_time_left <= 0.0

func paid_revive() -> void:
	if not is_dead:
		return
	var zone_entrance := get_node_or_null(zone_entrance_path) as Node3D
	if zone_entrance == null:
		push_warning("مدخل الـZone غير محدد؛ تعذر الإحياء المدفوع.")
		return
	_complete_revive(zone_entrance.global_position, PAID_REVIVE_HEALTH_RATIO)
	protection_time_left = PAID_REVIVE_PROTECTION_SECONDS


func free_return() -> void:
	if not is_dead:
		return
	inventory.apply_free_return_loss()
	_complete_revive(spawn_point, 1.0)


func _complete_revive(destination: Vector3, health_ratio: float) -> void:
	global_position = destination
	velocity = Vector3.ZERO
	health = MAX_HEALTH * health_ratio
	water = MAX_WATER
	is_dead = false
	health_changed.emit(health, MAX_HEALTH)
	water_changed.emit(water, MAX_WATER)
	revived.emit()
