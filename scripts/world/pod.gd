extends Node3D
## الغرفة الآمنة (The Pod): خزان ماء يعيد تعبئة الماء عند الاقتراب منه.

@onready var tank_area: Area3D = $WaterTank/Area3D
@onready var ceiling: CSGBox3D = $Ceiling
@onready var player: Node3D = get_parent().get_node_or_null("Player")

func _ready() -> void:
	tank_area.body_entered.connect(_on_tank_body_entered)
	_update_ceiling_cutaway()

func _process(_delta: float) -> void:
	_update_ceiling_cutaway()

## يخفي السقف فقط عندما يكون اللاعب داخل الـPod كي تبقى الغرفة مقروءة من الكاميرا الإيزومترية.
func _update_ceiling_cutaway() -> void:
	if not is_instance_valid(player):
		return
	var player_position := to_local(player.global_position)
	var player_inside := absf(player_position.x) < 1.15 and absf(player_position.z) < 1.15
	ceiling.visible = not player_inside

func _on_tank_body_entered(body: Node3D) -> void:
	if body.has_method("drink"):
		body.drink(100.0)
