extends CanvasLayer
## واجهة اللعب: الصحة، الماء، الحقيبة (16 خانة)، مؤشر التصويب، وعمق الطبقة.

const SLOT_SIZE := 46.0
const SAFE_SLOT_COLOR := Color(1.0, 1.0, 0.45)

@onready var health_bar: ProgressBar = $Root/TopLeft/HealthBar
@onready var water_bar: ProgressBar = $Root/TopLeft/WaterBar
@onready var depth_label: Label = $Root/DepthLabel
@onready var wall_label: Label = $Root/WallInfo
@onready var message_label: Label = $Root/Message
@onready var inventory_grid: GridContainer = $Root/InventoryPanel/Grid

var _player: CharacterBody3D
var _slot_labels: Array = []

func _ready() -> void:
	_player = get_parent().get_node("Player")
	_build_inventory_grid()

func _build_inventory_grid() -> void:
	for i in _player.inventory.SLOT_COUNT:
		var panel := Panel.new()
		panel.custom_minimum_size = Vector2(SLOT_SIZE, SLOT_SIZE)
		if _player.inventory.is_safe_slot(i):
			panel.self_modulate = SAFE_SLOT_COLOR
		var label := Label.new()
		label.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		label.add_theme_font_size_override("font_size", 10)
		label.clip_text = true
		panel.add_child(label)
		inventory_grid.add_child(panel)
		_slot_labels.append(label)

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

## يعرض محتوى الحقيبة: اسم العنصر في كل خانة، والخانات الفارغة بلا نص.
func update_inventory(items: Array) -> void:
	for i in _slot_labels.size():
		var id: String = items[i] if i < items.size() else ""
		_slot_labels[i].text = Items.DATA[id]["name"] if id != "" else ""

func _show_message(text: String, duration: float) -> void:
	message_label.text = text
	message_label.visible = true
	get_tree().create_timer(duration).timeout.connect(
		func() -> void:
			if message_label.text == text:
				message_label.visible = false
	)
