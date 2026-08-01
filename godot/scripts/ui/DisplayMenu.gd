extends Control
## HTML #display — resolution scale, tick rate, debug, fullscreen (set-card chrome).

const OverlayTheme = preload("res://scripts/ui/menu/OverlayTheme.gd")

@onready var scale_slider: HSlider = %ScaleSlider
@onready var scale_label: Label = %ScaleLabel
@onready var debug_btn: Button = %DebugBtn
@onready var hz_label: Label = %HzLabel
@onready var panel: PanelContainer = $Panel
@onready var title_l: Label = $Panel/VBox/Title
@onready var close_btn: Button = $Panel/VBox/CloseBtn
@onready var fs_btn: Button = $Panel/VBox/FsBtn
@onready var hz30: Button = $Panel/VBox/HzRow/Hz30
@onready var hz60: Button = $Panel/VBox/HzRow/Hz60
@onready var hz120: Button = $Panel/VBox/HzRow/Hz120

var _preset_row: HBoxContainer
var _sub_label: Label
var _fs_label: Label
var _styled := false

func _ready() -> void:
	visible = false
	process_mode = Node.PROCESS_MODE_ALWAYS
	add_to_group("display_menu")
	if scale_slider:
		scale_slider.value = Config.display_scale * 100.0
	_ensure_chrome()
	_style_once()
	_refresh()

func open_menu() -> void:
	visible = true
	_style_once()
	_refresh()

func close_menu() -> void:
	visible = false

func _ensure_chrome() -> void:
	## Inject HTML-like section labels + scale presets if scene is still minimal.
	var vbox: VBoxContainer = $Panel/VBox if has_node("Panel/VBox") else null
	if vbox == null:
		return
	if title_l:
		title_l.text = "🖥 DISPLAY"
	if not has_node("Panel/VBox/Sub"):
		_sub_label = Label.new()
		_sub_label.name = "Sub"
		_sub_label.text = "Resolution, refresh rate, debug & fullscreen"
		_sub_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		vbox.add_child(_sub_label)
		vbox.move_child(_sub_label, 1)
	else:
		_sub_label = $Panel/VBox/Sub
	if not has_node("Panel/VBox/SecScale"):
		var sec := Label.new()
		sec.name = "SecScale"
		sec.text = "RESOLUTION SCALE"
		vbox.add_child(sec)
		vbox.move_child(sec, scale_label.get_index() if scale_label else 2)
	if not has_node("Panel/VBox/PresetRow"):
		_preset_row = HBoxContainer.new()
		_preset_row.name = "PresetRow"
		_preset_row.alignment = BoxContainer.ALIGNMENT_CENTER
		_preset_row.add_theme_constant_override("separation", 8)
		for pct in [50, 75, 100]:
			var b := Button.new()
			b.text = "%d%%" % pct
			b.custom_minimum_size = Vector2(72, 32)
			var p: int = int(pct)
			b.pressed.connect(func(): _on_preset(p))
			_preset_row.add_child(b)
		var insert_at := scale_slider.get_index() + 1 if scale_slider else vbox.get_child_count()
		vbox.add_child(_preset_row)
		vbox.move_child(_preset_row, insert_at)
	else:
		_preset_row = $Panel/VBox/PresetRow
	if not has_node("Panel/VBox/SecHz"):
		var sec2 := Label.new()
		sec2.name = "SecHz"
		sec2.text = "SIMULATION REFRESH"
		var hi := hz_label.get_index() if hz_label else vbox.get_child_count()
		vbox.add_child(sec2)
		vbox.move_child(sec2, hi)
	if not has_node("Panel/VBox/SecOverlay"):
		var sec3 := Label.new()
		sec3.name = "SecOverlay"
		sec3.text = "OVERLAYS"
		var di := debug_btn.get_index() if debug_btn else vbox.get_child_count()
		vbox.add_child(sec3)
		vbox.move_child(sec3, di)
	if not has_node("Panel/VBox/FsStatus"):
		_fs_label = Label.new()
		_fs_label.name = "FsStatus"
		_fs_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		var fi := fs_btn.get_index() if fs_btn else vbox.get_child_count()
		vbox.add_child(_fs_label)
		vbox.move_child(_fs_label, fi)
	else:
		_fs_label = $Panel/VBox/FsStatus

func _style_once() -> void:
	if _styled:
		return
	_styled = true
	if panel:
		panel.add_theme_stylebox_override("panel", OverlayTheme.card_style(Color(0.55, 0.45, 0.95, 0.85), 18.0))
		# Wider card closer to HTML set-card
		panel.offset_left = -230.0
		panel.offset_right = 230.0
		panel.offset_top = -220.0
		panel.offset_bottom = 220.0
	if title_l:
		OverlayTheme.style_label(title_l)
		title_l.add_theme_color_override("font_color", OverlayTheme.TITLE_SET)
		title_l.add_theme_font_size_override("font_size", 22)
	if _sub_label:
		OverlayTheme.style_label(_sub_label)
		_sub_label.add_theme_color_override("font_color", OverlayTheme.SUB)
		_sub_label.add_theme_font_size_override("font_size", 12)
	for n in ["SecScale", "SecHz", "SecOverlay"]:
		if has_node("Panel/VBox/" + n):
			OverlayTheme.style_sec(get_node("Panel/VBox/" + n) as Label)
	if scale_label:
		OverlayTheme.style_label(scale_label)
	if hz_label:
		OverlayTheme.style_label(hz_label)
	if _fs_label:
		OverlayTheme.style_label(_fs_label)
	if scale_slider:
		OverlayTheme.style_slider(scale_slider)
	if debug_btn:
		OverlayTheme.style_button(debug_btn, "ghost")
	if fs_btn:
		OverlayTheme.style_button(fs_btn, "ghost")
	if close_btn:
		OverlayTheme.style_button(close_btn, "primary")
		close_btn.text = "Done"
	for b in [hz30, hz60, hz120]:
		if b:
			OverlayTheme.style_button(b, "ghost")
	if _preset_row:
		for c in _preset_row.get_children():
			if c is Button:
				OverlayTheme.style_button(c as Button, "ghost")

func _on_preset(pct: int) -> void:
	if scale_slider:
		scale_slider.value = float(pct)
	_on_scale_changed(float(pct))

func _refresh() -> void:
	var sc := int(round(Config.display_scale * 100.0))
	if scale_label:
		scale_label.text = "Scale  %d%%" % sc
	if scale_slider and absf(scale_slider.value - float(sc)) > 0.5:
		scale_slider.set_value_no_signal(float(sc))
	if hz_label:
		hz_label.text = "Tick rate  %d Hz" % Config.refresh_rate
	if debug_btn:
		debug_btn.text = "Debug layer: %s — Show FPS / state / coords" % ("ON" if Config.debug_layer else "OFF")
		debug_btn.button_pressed = Config.debug_layer
	if _fs_label:
		var fs := DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN
		_fs_label.text = "Mode  %s" % ("Fullscreen" if fs else "Windowed")
	_highlight_hz()
	_highlight_preset(sc)

func _highlight_hz() -> void:
	var hz := Config.refresh_rate
	for pair in [[hz30, 30], [hz60, 60], [hz120, 120]]:
		var b: Button = pair[0]
		var v: int = pair[1]
		if b == null:
			continue
		if v == hz:
			OverlayTheme.style_button(b, "primary")
		else:
			OverlayTheme.style_button(b, "ghost")

func _highlight_preset(sc: int) -> void:
	if _preset_row == null:
		return
	for c in _preset_row.get_children():
		if c is Button:
			var t := (c as Button).text.replace("%", "")
			if t.is_valid_int() and int(t) == sc:
				OverlayTheme.style_button(c as Button, "primary")
			else:
				OverlayTheme.style_button(c as Button, "ghost")

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
	_refresh()

func _on_close() -> void:
	close_menu()
