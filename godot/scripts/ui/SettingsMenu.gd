extends Control

@onready var music_slider: HSlider = %MusicSlider
@onready var sfx_slider: HSlider = %SfxSlider

func _ready() -> void:
	visible = false
	process_mode = Node.PROCESS_MODE_ALWAYS
	GameState.state_changed.connect(func(s):
		visible = (s == &"SETTINGS")
	)

func _on_music(v: float) -> void:
	AudioBus.set_music_volume(v / 100.0)

func _on_sfx(v: float) -> void:
	AudioBus.set_sfx_volume(v / 100.0)

func _on_display() -> void:
	var dm := get_tree().get_first_node_in_group("display_menu")
	if dm and dm.has_method("open_menu"):
		dm.open_menu()

func _on_close() -> void:
	GameState.return_to_title()
