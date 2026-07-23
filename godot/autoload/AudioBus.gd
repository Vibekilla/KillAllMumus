extends Node
## Lightweight SFX bus (procedural blips). Music via stream later.

var sfx_volume: float = 0.9
var music_volume: float = 1.0
var _player: AudioStreamPlayer

func _ready() -> void:
	_player = AudioStreamPlayer.new()
	add_child(_player)

func play_sfx(_name: String) -> void:
	# Placeholder — wire AudioStream samples under assets/audio/
	pass

func set_sfx_volume(v: float) -> void:
	sfx_volume = clampf(v, 0.0, 1.0)

func set_music_volume(v: float) -> void:
	music_volume = clampf(v, 0.0, 1.0)
