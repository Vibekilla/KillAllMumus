extends Control
## Resolution scale, refresh rate, debug, fullscreen.

@onready var scale_slider: HSlider = %ScaleSlider
@onready var scale_label: Label = %ScaleLabel
@onready var debug_btn: Button = %DebugBtn
@onready var hz_label: Label = %HzLabel

func _ready() -> void:
	visible = false
	process_mode = Node.PROCESS_MODE_ALWAYS
	scale_slider.value = Config.display_scale * 100.0
	_refresh()

func open_menu() -> void:
	visible = true
	_refresh()

func close_menu() -> void:
	visible = false

func _refresh() -> void:
	scale_label.text = "%d%%" % int(Config.display_scale * 100)
	hz_label.text = "%d Hz" % Config.refresh_rate
	debug_btn.text = "Debug layer: %s" % ("ON" if Config.debug_layer else "OFF")
	debug_btn.button_pressed = Config.debug_layer

func _on_scale_changed(v: float) -> void:
	Config.display_scale = clampf(v / 100.0, 0.5, 1.0)
	_refresh()
	get_window().content_scale_factor = Config.display_scale

func _on_hz_30() -> void:
	Config.refresh_rate = 30
	Engine.physics_ticks_per_second = 30
	_refresh()

func _on_hz_60() -> void:
	Config.refresh_rate = 60
	Engine.physics_ticks_per_second = 60
	_refresh()

func _on_hz_120() -> void:
	Config.refresh_rate = 120
	Engine.physics_ticks_per_second = 120
	_refresh()

func _on_debug_toggled(on: bool) -> void:
	Config.debug_layer = on
	_refresh()

func _on_fullscreen() -> void:
	if DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)

func _on_close() -> void:
	close_menu()
