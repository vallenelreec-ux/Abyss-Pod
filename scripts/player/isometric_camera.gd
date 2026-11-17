extends Node3D
## كاميرا إيزومترية ثابتة: زاويتها مقفولة ولا تدور أبداً، وتتبع اللاعب بسلاسة.

const FOLLOW_SMOOTHING := 5.0
## إزاحة رأسية صغيرة لتوسيط جسم اللاعب على الشاشة.
const TARGET_OFFSET := Vector3(0, 1, 0)

@export var target_path: NodePath
@export var follow_speed := 5.0

var _target: Node3D

func _ready() -> void:
	_target = get_node_or_null(target_path) as Node3D

func _process(delta: float) -> void:
	if _target == null:
		return
	var weight := 1.0 - exp(-follow_speed * delta)
	global_position = global_position.lerp(_target.global_position + TARGET_OFFSET, weight)
