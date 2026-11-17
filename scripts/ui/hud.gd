extends CanvasLayer
## واجهة اللعب: الصحة، الماء، الحقيبة (16 خانة)، مؤشر التصويب، وعمق الطبقة.

const SLOT_SIZE := 52.0
const SLOT_TEXT_COLOR := Color(0.94, 0.91, 0.82, 1.0)

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
		var slot_style := StyleBoxFlat.new()
		slot_style.bg_color = Color(0.055, 0.065, 0.075, 0.96)
		slot_style.border_width_left = 1
		slot_style.border_width_top = 1
		slot_style.border_width_right = 1
		slot_style.border_width_bottom = 1
		slot_style.corner_radius_top_left = 6
		slot_style.corner_radius_top_right = 6
		slot_style.corner_radius_bottom_right = 6
		slot_style.corner_radius_bottom_left = 6
		if _player.inventory.is_safe_slot(i):
			slot_style.bg_color = Color(0.14, 0.13, 0.075, 0.98)
			slot_style.border_color = Color(0.85, 0.72, 0.3, 1.0)
		else:
			slot_style.border_color = Color(0.34, 0.4, 0.43, 0.9)
		panel.add_theme_stylebox_override("panel", slot_style)
		var label := Label.new()
		label.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		label.add_theme_font_size_override("font_size", 12)
		label.add_theme_color_override("font_color", SLOT_TEXT_COLOR)
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
