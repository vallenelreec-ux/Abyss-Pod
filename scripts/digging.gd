extends Node
## نظام الحفر: ضربات الفأس الخشبي تُنقص صحة الجدار وتستهلك الماء.

signal wall_hit(hp: float, max_hp: float)

const AXE_DAMAGE := 10.0
const HITS_PER_WATER_TICK := 5
const WATER_COST_PER_TICK := 1.0
const SWING_COOLDOWN := 0.45

var _hits_since_water_tick := 0

@onready var player: CharacterBody3D = get_parent()
@onready var ray: RayCast3D = player.get_node("Head/DigRay")
@onready var swing_timer: Timer = $SwingTimer

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("dig") and swing_timer.is_stopped():
		swing()

func swing() -> void:
	swing_timer.start(SWING_COOLDOWN)
	if not ray.is_colliding():
		return
	var target: Object = ray.get_collider()
	if target is Node and target.has_method("take_damage"):
		target.take_damage(AXE_DAMAGE)
		_hits_since_water_tick += 1
		if _hits_since_water_tick >= HITS_PER_WATER_TICK:
			_hits_since_water_tick = 0
			player.use_water(WATER_COST_PER_TICK)
		if "hp" in target:
			wall_hit.emit(target.hp, target.max_hp)
