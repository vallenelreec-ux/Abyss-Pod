extends Node3D
## المشهد الرئيسي: يربط إشارات اللاعب بالواجهة.

@onready var player: PlayerCharacter = $Player
@onready var hud: GameHUD = $HUD
@onready var digger: Node = $Player/Digging

func _ready() -> void:
	player.health_changed.connect(hud.on_health_changed)
	player.water_changed.connect(hud.on_water_changed)
	player.died.connect(hud.on_player_died)
	player.revived.connect(hud.on_player_revived)
	hud.paid_revive_selected.connect(player.paid_revive)
	hud.free_return_selected.connect(player.free_return)
	digger.wall_hit.connect(hud.on_wall_hit)
	player.inventory.changed.connect(hud.update_inventory)
	hud.update_inventory(player.inventory.items)
