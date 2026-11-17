extends Node3D
## يولد شبكة خلايا متصلة. كل جدار مكسور يفتح خلية جديدة ويكشف جدراناً مجاورة.

const CELL_SIZE := 2.0
const FLOOR_THICKNESS := 0.2
const CARDINAL_DIRECTIONS: Array[Vector2i] = [
	Vector2i.RIGHT,
	Vector2i.LEFT,
	Vector2i.UP,
	Vector2i.DOWN,
]

@export var world_seed: int = 0

var _rng := RandomNumberGenerator.new()
var _open_cells: Dictionary = {}
var _walls: Dictionary = {}
var _floor_material := StandardMaterial3D.new()


func _ready() -> void:
	if world_seed == 0:
		_rng.randomize()
	else:
		_rng.seed = world_seed

	_floor_material.albedo_color = Color(0.35, 0.3, 0.25, 1.0)
	_floor_material.roughness = 1.0
	_open_cells[Vector2i.ZERO] = true
	_add_floor_tile(Vector2i.ZERO)

	for direction in CARDINAL_DIRECTIONS:
		_spawn_wall(direction)


func _spawn_wall(cell: Vector2i) -> void:
	if _open_cells.has(cell) or _walls.has(cell):
		return

	var wall := preload("res://scenes/world/Wall.tscn").instantiate() as DiggableWall
	if wall == null:
		push_error("تعذر إنشاء جدار قابل للحفر.")
		return

	wall.position = Vector3(cell.x * CELL_SIZE, 1.0, cell.y * CELL_SIZE)
	wall.hint = _rng.randi_range(0, 3)
	_walls[cell] = wall
	add_child(wall)
	wall.destroyed.connect(_on_wall_destroyed.bind(cell))


func _on_wall_destroyed(_wall: DiggableWall, cell: Vector2i) -> void:
	_walls.erase(cell)
	if _open_cells.has(cell):
		return

	_open_cells[cell] = true
	_add_floor_tile(cell)
	for direction in CARDINAL_DIRECTIONS:
		_spawn_wall(cell + direction)


func _add_floor_tile(cell: Vector2i) -> void:
	var floor_tile := CSGBox3D.new()
	floor_tile.name = "Floor_%d_%d" % [cell.x, cell.y]
	floor_tile.use_collision = true
	floor_tile.size = Vector3(CELL_SIZE, FLOOR_THICKNESS, CELL_SIZE)
	floor_tile.position = Vector3(cell.x * CELL_SIZE, -FLOOR_THICKNESS * 0.5, cell.y * CELL_SIZE)
	floor_tile.material = _floor_material
	add_child(floor_tile)

