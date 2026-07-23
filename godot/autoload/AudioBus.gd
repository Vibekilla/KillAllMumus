extends Node
## SFX + music bus — full HTML sfx() parity via SfxSynth.

var sfx_volume: float = 0.9
var music_volume: float = 1.0
var _synth: Node

func _ready() -> void:
	_synth = preload("res://scripts/audio/SfxSynth.gd").new()
	add_child(_synth)

func play_sfx(name: String, vmul: float = 1.0) -> void:
	if _synth and _synth.has_method("play"):
		_synth.play(name, vmul * sfx_volume)

func sfx(type: String, vmul: float = 1.0) -> void:
	play_sfx(type, vmul)

func set_sfx_volume(v: float) -> void:
	sfx_volume = clampf(v, 0.0, 1.0)
	if _synth and _synth.has_method("set_sfx_volume"):
		_synth.set_sfx_volume(sfx_volume)

func set_music_volume(v: float) -> void:
	music_volume = clampf(v, 0.0, 1.0)
	if _synth and _synth.has_method("set_music_volume"):
		_synth.set_music_volume(music_volume)
	# HTML applyMusicVol → YT player volume
	if MusicBridge:
		MusicBridge.set_volume(music_volume)
