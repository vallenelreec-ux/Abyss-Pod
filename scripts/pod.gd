extends Node3D
## الغرفة الآمنة (The Pod): خزان ماء يعيد تعبئة الماء عند الاقتراب منه.

@onready var tank_area: Area3D = $WaterTank/Area3D

func _ready() -> void:
	tank_area.body_entered.connect(_on_tank_body_entered)

func _on_tank_body_entered(body: Node3D) -> void:
	if body.has_method("drink"):
		body.drink(100.0)
