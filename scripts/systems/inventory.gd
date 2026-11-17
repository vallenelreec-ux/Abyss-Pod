extends Node
## نظام المخزون: 16 خانة فقط، كل عنصر يشغل خانة واحدة (بلا تكديس)،
## والخانتان الأخيرتان آمنتان ولا يفقد محتواهما عند الموت (المرحلة 5).

signal changed(items: Array)

const SLOT_COUNT := 16
const SAFE_SLOTS := [14, 15]

var items: Array = []
var equipped_item_ids: Array[String] = []

func _ready() -> void:
	items.resize(SLOT_COUNT)
	items.fill("")

func is_safe_slot(index: int) -> bool:
	return index in SAFE_SLOTS

## يضيف عنصراً في أول خانة فارغة. prefer_safe يبحث في الخانات الآمنة أولاً.
## يعيد false إن امتلأت الحقيبة — قرار تكتيكي: ماذا يحمل اللاعب وماذا يترك.
func add_item(item_id: String, prefer_safe := false) -> bool:
	if item_id.is_empty():
		return false
	var order: Array = range(SLOT_COUNT)
	if prefer_safe:
		order = SAFE_SLOTS.duplicate()
		for i in range(SLOT_COUNT):
			if not order.has(i):
				order.append(i)
	for i in order:
		if items[i] == "":
			items[i] = item_id
			changed.emit(items)
			return true
	return false

func remove_item(item_id: String) -> bool:
	for i in SLOT_COUNT:
		if items[i] == item_id:
			items[i] = ""
			changed.emit(items)
			return true
	return false

func has_item(item_id: String) -> bool:
	return items.has(item_id)

func equip_item(item_id: String) -> bool:
	if not has_item(item_id):
		return false
	if not equipped_item_ids.has(item_id):
		equipped_item_ids.append(item_id)
	return true

## عند Free Return تُفقد الغنائم العادية، وتبقى الأدوات المجهزة والخانات الآمنة.
func apply_free_return_loss() -> void:
	for i in range(SLOT_COUNT):
		if items[i].is_empty() or is_safe_slot(i) or equipped_item_ids.has(items[i]):
			continue
		items[i] = ""
	changed.emit(items)

func is_full() -> bool:
	return not items.has("")

## الخانات الآمنة فقط: تُستخدم لحفظ الموارد النادرة.
func add_to_safe_slot(item_id: String) -> bool:
	if item_id.is_empty():
		return false
	for i in SAFE_SLOTS:
		if items[i] == "":
			items[i] = item_id
			changed.emit(items)
			return true
	return add_item(item_id)
