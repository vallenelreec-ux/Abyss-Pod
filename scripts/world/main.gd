extends Node3D
## المشهد الرئيسي: يربط إشارات اللاعب بالواجهة.

@onready var player: CharacterBody3D = $Player
@onready var hud: CanvasLayer = $HUD
@onready var digger: Node = $Player/Digging

func _ready() -> void:
	player.health_changed.connect(hud.on_health_changed)
	player.water_changed.connect(hud.on_water_changed)
	player.died.connect(hud.on_player_died)
	digger.wall_hit.connect(hud.on_wall_hit)
