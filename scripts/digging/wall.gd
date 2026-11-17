extends StaticBody3D
## جدار قابل للتدمير. صوت الضربة يكشف ما خلفه: صخر، معدن، فراغ، أو ماء.

signal destroyed(wall: StaticBody3D)

enum Hint { ROCK, METAL, VOID, WATER }

const HIT_FREQUENCY := {
	Hint.ROCK: 220.0,
	Hint.METAL: 880.0,
	Hint.VOID: 110.0,
	Hint.WATER: 480.0,
}
const HIT_DURATION := {
	Hint.ROCK: 0.10,
	Hint.METAL: 0.14,
	Hint.VOID: 0.30,
	Hint.WATER: 0.18,
}

@export var max_hp := 50.0
@export var hint: Hint = Hint.ROCK

var hp := 50.0
var _base_color := Color(0.55, 0.45, 0.35)

@onready var mesh: CSGBox3D = $Mesh
@onready var audio: AudioStreamPlayer3D = $Audio

func _ready() -> void:
	hp = max_hp
	var mat := mesh.material as StandardMaterial3D
	if mat != null:
		_base_color = mat.albedo_color
	audio.stream = HitSound.make(HIT_FREQUENCY[hint], HIT_DURATION[hint])

func take_damage(amount: float) -> void:
	if hp <= 0.0:
		return
	hp = maxf(hp - amount, 0.0)
	_play_hit_sound()
	_flash()
	if hp <= 0.0:
		destroyed.emit(self)
		queue_free()

func _play_hit_sound() -> void:
	audio.pitch_scale = randf_range(0.95, 1.05)
	audio.play()

func _flash() -> void:
	var mat := mesh.material as StandardMaterial3D
	if mat == null:
		return
	mat.albedo_color = Color(1.0, 0.35, 0.25)
	var tween := create_tween()
	tween.tween_property(mat, "albedo_color", _base_color, 0.2)
