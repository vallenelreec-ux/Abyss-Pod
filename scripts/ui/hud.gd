extends CanvasLayer
## واجهة اللعب: الصحة، الماء، مؤشر التصويب، وعمق الطبقة.

@onready var health_bar: ProgressBar = $Root/TopLeft/HealthBar
@onready var water_bar: ProgressBar = $Root/TopLeft/WaterBar
@onready var depth_label: Label = $Root/DepthLabel
@onready var wall_label: Label = $Root/WallInfo
@onready var message_label: Label = $Root/Message

var _player: CharacterBody3D

func _ready() -> void:
	_player = get_parent().get_node("Player")

func _process(_delta: float) -> void:
	var depth := maxf(0.0, -_player.global_position.y)
	depth_label.text = "الطبقة %d — العمق %.0f م" % [1 + int(depth / 10.0), depth]

func on_health_changed(value: float, max_value: float) -> void:
	health_bar.max_value = max_value
	health_bar.value = value

func on_water_changed(value: float, max_value: float) -> void:
	water_bar.max_value = max_value
	water_bar.value = value
	if value <= 0.0:
		_show_message("الماء نفد! عُد إلى الغرفة الآمنة فوراً", 2.0)
	else:
		message_label.visible = false

func on_wall_hit(hp: float, max_hp: float) -> void:
	wall_label.text = "حالة الجدار: %d / %d" % [int(maxf(hp, 0.0)), int(max_hp)]

func on_player_died() -> void:
	_show_message("لقد مت! عدت إلى الغرفة الآمنة", 3.0)

func _show_message(text: String, duration: float) -> void:
	message_label.text = text
	message_label.visible = true
	get_tree().create_timer(duration).timeout.connect(
		func() -> void:
			if message_label.text == text:
				message_label.visible = false
	)
