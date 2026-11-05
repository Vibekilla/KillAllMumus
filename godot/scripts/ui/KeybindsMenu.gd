extends Control
## HTML #keybinds — mouse feel plus keyboard rebinds.
## Button text is HTML keyName (keyboard only). Joypad rebinds still apply via _apply_joy_bind.

const GamepadMap = preload("res://scripts/input/GamepadMap.gd")
const JoypadLabels = preload("res://scripts/input/JoypadLabels.gd")
const OverlayTheme = preload("res://scripts/ui/menu/OverlayTheme.gd")

## HTML BIND_LIST order and labels. Action ids stay the Godot InputMap names
## (HTML calls cycle_special "cycle").
const ACTIONS := [
	{"action": "shoot", "label": "Fire"},
	{"action": "focus", "label": "Focus / Dash"},
	{"action": "melee", "label": "Melee (hold=charge)"},
	{"action": "meleeswap", "label": "Switch Melee"},
	{"action": "bomb", "label": "Bomb"},
	{"action": "swap", "label": "Swap Weapon"},
	{"action": "special", "label": "Use Special"},
	{"action": "cycle_special", "label": "Cycle Special"},
	{"action": "item_switch", "label": "Switch Item"},
	{"action": "item_use", "label": "Use Item (tap)"},
	{"action": "interact", "label": "Interact / Shop"},
	{"action": "pause", "label": "Pause"},
]

const DEFAULTS := {
	"shoot": KEY_Z,
	"focus": KEY_SHIFT,
	"melee": KEY_SPACE,
	"meleeswap": KEY_D,
	"bomb": KEY_X,
	"swap": KEY_C,
	"special": KEY_V,
	"cycle_special": KEY_B,
	"pause": KEY_P,
	"interact": KEY_E,
	"item_switch": KEY_A,
	"item_use": KEY_Q,
}

const SUB_COPY := "She follows your cursor — tune the mouse feel, then rebind any key below"
const KEY_HINT := "click a key, then press the new key · Esc is bindable · arrow keys always nudge her"
const WAITING := "press…"

@onready var list: VBoxContainer = %List
var _waiting_action: String = ""
var _row_btns: Dictionary = {}  # action -> Button
var follow_slider: HSlider
var speed_slider: HSlider
var follow_label: Label
var speed_label: Label

func _ready() -> void:
	visible = false
	process_mode = Node.PROCESS_MODE_ALWAYS
	# Above PauseMenu (z 80) so Settings → Controls and Pause → Controls both show the card.
	z_index = 90
	z_as_relative = false
	add_to_group("keybinds_menu")
	_apply_html_chrome()
	_build_list()
	_layout_card()
	var dim := get_node_or_null("Dim") as ColorRect
	if dim and not dim.gui_input.is_connected(_on_dim_gui):
		dim.gui_input.connect(_on_dim_gui)

func open_menu() -> void:
	visible = true
	_waiting_action = ""
	_layout_card()
	_sync_sliders()
	_refresh_labels()

func close_menu() -> void:
	visible = false
	_waiting_action = ""

func _viewport_size() -> Vector2:
	var vs := get_viewport_rect().size
	if vs.y < 64.0:
		vs = Vector2(960, 540)
		if Config:
			vs = Vector2(Config.W, Config.H)
	return vs

func _layout_card() -> void:
	## HTML .set-card width min(440px, 94vw), max-height 92dvh. Title, subtitle,
	## Reset, and Done stay put. Mouse + key rows live in the scroll.
	var panel := get_node_or_null("Panel") as Control
	if panel == null:
		return
	var vs := _viewport_size()
	var max_h := vs.y * 0.92
	var w := minf(440.0, vs.x * 0.94)
	panel.offset_left = -w * 0.5
	panel.offset_right = w * 0.5
	panel.offset_top = -max_h * 0.5
	panel.offset_bottom = max_h * 0.5
	var vbox := panel.get_node_or_null("VBox") as VBoxContainer
	if vbox:
		vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		vbox.size_flags_vertical = Control.SIZE_EXPAND_FILL
	var scroll := panel.get_node_or_null("VBox/Scroll") as ScrollContainer
	if scroll:
		scroll.custom_minimum_size = Vector2(0, 0)
		scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
		scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
		scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO

func _apply_html_chrome() -> void:
	var dim := get_node_or_null("Dim") as ColorRect
	var panel := get_node_or_null("Panel") as PanelContainer
	if dim:
		OverlayTheme.ensure_backbuffer_copy(self)
		var mat := ShaderMaterial.new()
		mat.shader = OverlayTheme.DIM_SHADER
		var veil := Color(6.0 / 255.0, 4.0 / 255.0, 10.0 / 255.0, 0.75)
		mat.set_shader_parameter("inner", veil)
		mat.set_shader_parameter("outer", Color(6.0 / 255.0, 4.0 / 255.0, 10.0 / 255.0, 0.82))
		mat.set_shader_parameter("radial", 0.0)
		mat.set_shader_parameter("blur_px", 3.0)
		dim.color = veil
		dim.material = mat
		dim.mouse_filter = Control.MOUSE_FILTER_STOP
	if panel:
		var sb := OverlayTheme.card_style(OverlayTheme.VIOLET, 18.0)
		sb.bg_color = OverlayTheme.CARD_TOP
		panel.add_theme_stylebox_override("panel", sb)
		panel.mouse_filter = Control.MOUSE_FILTER_STOP
	var vbox := panel.get_node_or_null("VBox") if panel else null
	var title := (vbox.get_node_or_null("Title") if vbox else null) as Label
	if title:
		title.text = "🎮 CONTROLS"
		title.add_theme_color_override("font_color", OverlayTheme.TITLE_SET)
		title.add_theme_font_size_override("font_size", 22)
		if FontBank and FontBank.ui_bold:
			title.add_theme_font_override("font", FontBank.ui_bold)
		elif FontBank and FontBank.ui:
			title.add_theme_font_override("font", FontBank.ui)
	var sub := (vbox.get_node_or_null("Sub") if vbox else null) as Label
	if sub:
		sub.text = SUB_COPY
		sub.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		sub.add_theme_color_override("font_color", OverlayTheme.SUB)
		sub.add_theme_font_size_override("font_size", 12)
		if FontBank and FontBank.ui:
			sub.add_theme_font_override("font", FontBank.ui)
	var reset_btn := (vbox.get_node_or_null("ResetBtn") if vbox else null) as Button
	var done_btn := (vbox.get_node_or_null("DoneBtn") if vbox else null) as Button
	# #kb-reset is pink text; #kb-done is the cyan button.
	OverlayTheme.style_button(reset_btn, "done")
	if reset_btn:
		reset_btn.text = "↺ Reset keys to defaults"
		reset_btn.custom_minimum_size.y = 42
	OverlayTheme.style_button(done_btn, "cyan")
	if done_btn:
		done_btn.text = "Done"
		done_btn.custom_minimum_size.y = 46

func _on_dim_gui(event: InputEvent) -> void:
	## HTML: click the backdrop (not the card) closes the modal.
	if not visible:
		return
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		close_menu()
		var dim := get_node_or_null("Dim") as Control
		if dim:
			dim.accept_event()

func _build_list() -> void:
	if list == null:
		return
	for c in list.get_children():
		c.queue_free()
	_row_btns.clear()
	_add_section("MOUSE")
	follow_label = _add_value_label("FollowLabel", "Cursor Follow Tightness")
	follow_slider = _add_slider("FollowSlider", 35.0, 100.0, _on_follow)
	_add_hint("Higher = she snaps to the cursor instantly. Lower = smooth, floaty trailing.")
	speed_label = _add_value_label("SpeedLabel", "Movement Speed")
	speed_slider = _add_slider("SpeedSlider", 70.0, 160.0, _on_speed)
	_add_hint("How fast she flies overall.")
	_add_section("KEYBINDS")
	var hint := Label.new()
	hint.name = "KeyHint"
	hint.text = KEY_HINT
	hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hint.add_theme_color_override("font_color", OverlayTheme.SUB)
	hint.add_theme_font_size_override("font_size", 12)
	if FontBank and FontBank.ui:
		hint.add_theme_font_override("font", FontBank.ui)
	list.add_child(hint)
	for a in ACTIONS:
		var row := HBoxContainer.new()
		row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_theme_constant_override("separation", 10)
		var lab := Label.new()
		lab.text = str(a["label"])
		lab.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		lab.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		lab.add_theme_color_override("font_color", OverlayTheme.TITLE_SET)
		lab.add_theme_font_size_override("font_size", 13)
		if FontBank and FontBank.ui:
			lab.add_theme_font_override("font", FontBank.ui)
		var btn := Button.new()
		btn.custom_minimum_size = Vector2(78, 28)
		var act := str(a["action"])
		btn.pressed.connect(func(): _start_rebind(act))
		row.add_child(lab)
		row.add_child(btn)
		list.add_child(row)
		_row_btns[act] = btn
	_sync_sliders()
	_refresh_labels()

func _add_section(text: String) -> void:
	var sec := Label.new()
	sec.text = text
	OverlayTheme.style_sec(sec)
	list.add_child(sec)

func _add_value_label(node_name: String, left: String) -> Label:
	var lab := Label.new()
	lab.name = node_name
	lab.text = left
	lab.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	OverlayTheme.style_label(lab)
	list.add_child(lab)
	return lab

func _add_slider(node_name: String, mn: float, mx: float, cb: Callable) -> HSlider:
	var s := HSlider.new()
	s.name = node_name
	s.min_value = mn
	s.max_value = mx
	s.step = 1.0
	s.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	OverlayTheme.style_slider(s)
	s.value_changed.connect(cb)
	list.add_child(s)
	return s

func _add_hint(text: String) -> void:
	var hint := Label.new()
	hint.text = text
	hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	hint.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hint.add_theme_color_override("font_color", OverlayTheme.HINT)
	hint.add_theme_font_size_override("font_size", 11)
	if FontBank and FontBank.ui:
		hint.add_theme_font_override("font", FontBank.ui)
	list.add_child(hint)

func _sync_sliders() -> void:
	var st: Dictionary = {}
	if ProgressStore:
		var raw = ProgressStore.progress.get("settings", {})
		if typeof(raw) == TYPE_DICTIONARY:
			st = raw
	var follow := float(st.get("follow", Config.mouse_follow if Config else 0.6))
	if follow <= 1.0:
		follow *= 100.0
	var mspeed := float(st.get("mspeed", Config.mouse_speed if Config else 1.12))
	if mspeed <= 2.0:
		mspeed *= 100.0
	if follow_slider:
		follow_slider.set_value_no_signal(clampf(follow, 35.0, 100.0))
	if speed_slider:
		speed_slider.set_value_no_signal(clampf(mspeed, 70.0, 160.0))
	_refresh_mouse_labels()

func _refresh_mouse_labels() -> void:
	if follow_label and follow_slider:
		OverlayTheme.set_row_value(follow_label, "Cursor Follow Tightness", "%d%%" % int(follow_slider.value))
	if speed_label and speed_slider:
		OverlayTheme.set_row_value(speed_label, "Movement Speed", "%.2f×" % (speed_slider.value / 100.0))

func _on_follow(v: float) -> void:
	if Config:
		Config.mouse_follow = clampf(v / 100.0, 0.35, 1.0)
		_save_setting("follow", Config.mouse_follow)
	_refresh_mouse_labels()
	_mirror_pause()

func _on_speed(v: float) -> void:
	if Config:
		Config.mouse_speed = clampf(v / 100.0, 0.7, 1.6)
		_save_setting("mspeed", Config.mouse_speed)
	_refresh_mouse_labels()
	_mirror_pause()

func _mirror_pause() -> void:
	var pause := get_parent().get_node_or_null("PauseMenu") if get_parent() else null
	if pause and pause.visible and pause.has_method("_sync_ui"):
		pause._sync_ui()

func _save_setting(key: String, v) -> void:
	if ProgressStore == null:
		return
	var st: Dictionary = ProgressStore.progress.get("settings", {})
	if typeof(st) != TYPE_DICTIONARY:
		st = {}
	st[key] = v
	ProgressStore.progress["settings"] = st
	ProgressStore.queue_save()

func _key_name(action: String) -> String:
	## HTML keyName(binds[action]) — the keyboard key only. Gamepad glyphs stay off the button.
	if not InputMap.has_action(action):
		return "—"
	for e in InputMap.action_get_events(action):
		if e is InputEventKey:
			return JoypadLabels.event_label(e)
	return "—"

func _start_rebind(action: String) -> void:
	## HTML: clicking the waiting key again cancels.
	if _waiting_action == action:
		_waiting_action = ""
		_refresh_labels()
		return
	_waiting_action = action
	_refresh_labels()
	if AudioBus:
		AudioBus.sfx("item")

func _input(event: InputEvent) -> void:
	if not visible or _waiting_action == "":
		return
	if event is InputEventKey and event.pressed and not event.echo:
		_apply_key_bind(_waiting_action, event as InputEventKey)
		_waiting_action = ""
		_refresh_labels()
		get_viewport().set_input_as_handled()
	elif event is InputEventJoypadButton and event.pressed and not event.is_echo():
		_apply_joy_bind(_waiting_action, event as InputEventJoypadButton)
		_waiting_action = ""
		_refresh_labels()
		get_viewport().set_input_as_handled()

func _apply_key_bind(action: String, key: InputEventKey) -> void:
	## Replace keyboard events only — keep gamepad binds
	if not InputMap.has_action(action):
		InputMap.add_action(action)
	var keep: Array = []
	for e in InputMap.action_get_events(action):
		if e is InputEventJoypadButton or e is InputEventJoypadMotion:
			keep.append(e)
	InputMap.action_erase_events(action)
	var ev := InputEventKey.new()
	ev.physical_keycode = key.physical_keycode if key.physical_keycode != 0 else key.keycode
	ev.keycode = 0
	InputMap.action_add_event(action, ev)
	for e2 in keep:
		InputMap.action_add_event(action, e2)
	_save_binds()
	if AudioBus:
		AudioBus.sfx("graze")

func _apply_joy_bind(action: String, joy: InputEventJoypadButton) -> void:
	## Replace joypad-button events only — keep keyboard + axes
	if not InputMap.has_action(action):
		InputMap.add_action(action)
	var keep: Array = []
	for e in InputMap.action_get_events(action):
		if e is InputEventKey or e is InputEventJoypadMotion:
			keep.append(e)
	InputMap.action_erase_events(action)
	for e2 in keep:
		InputMap.action_add_event(action, e2)
	var ev := InputEventJoypadButton.new()
	ev.button_index = joy.button_index
	ev.pressed = true
	InputMap.action_add_event(action, ev)
	_save_binds()
	if AudioBus:
		AudioBus.sfx("graze")

func _refresh_labels() -> void:
	for act in _row_btns.keys():
		var btn: Button = _row_btns[act]
		var waiting := _waiting_action == str(act)
		btn.text = WAITING if waiting else _key_name(str(act))
		_style_key_btn(btn, waiting)

func _style_key_btn(b: Button, waiting: bool) -> void:
	## HTML .kb-key / .kb-key.waiting
	if b == null:
		return
	var sb := StyleBoxFlat.new()
	sb.set_corner_radius_all(8)
	sb.content_margin_left = 8
	sb.content_margin_right = 8
	sb.content_margin_top = 4
	sb.content_margin_bottom = 4
	sb.set_border_width_all(1)
	var col := Color.WHITE
	if waiting:
		sb.bg_color = Color(1.0, 210.0 / 255.0, 120.0 / 255.0, 0.22)
		sb.border_color = Color("ffd27a")
		col = Color("ffe08a")
	else:
		sb.bg_color = Color(1, 1, 1, 0.06)
		sb.border_color = Color(1, 1, 1, 0.22)
	b.add_theme_stylebox_override("normal", sb)
	b.add_theme_stylebox_override("hover", sb)
	b.add_theme_stylebox_override("pressed", sb)
	b.add_theme_stylebox_override("focus", sb)
	b.add_theme_color_override("font_color", col)
	b.add_theme_color_override("font_hover_color", col)
	b.add_theme_color_override("font_pressed_color", col)
	b.add_theme_font_size_override("font_size", 13)
	if FontBank:
		b.add_theme_font_override("font", FontBank.font_for("bold 13px monospace"))

func _save_binds() -> void:
	var out := {}
	for a in ACTIONS:
		var act := str(a["action"])
		out[act] = _key_name(act)
	if ProgressStore:
		var st: Dictionary = ProgressStore.progress.get("settings", {})
		if typeof(st) != TYPE_DICTIONARY:
			st = {}
		st["binds"] = out
		ProgressStore.progress["settings"] = st
		ProgressStore.queue_save()

func _on_reset() -> void:
	for act in DEFAULTS.keys():
		var action := str(act)
		if not InputMap.has_action(action):
			InputMap.add_action(action)
		InputMap.action_erase_events(action)
		var ev := InputEventKey.new()
		ev.physical_keycode = int(DEFAULTS[action])
		ev.keycode = 0
		InputMap.action_add_event(action, ev)
	# Restore Steam/desktop gamepad layer
	GamepadMap.ensure_defaults()
	_waiting_action = ""
	_refresh_labels()
	_save_binds()
	if AudioBus:
		AudioBus.sfx("item")

func _on_done() -> void:
	close_menu()
