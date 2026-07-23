extends Control
## HTML #pausescreen — full pause card (audio, mouse, resume, display, controls, menu).

const OverlayTheme = preload("res://scripts/ui/menu/OverlayTheme.gd")

@onready var music_slider: HSlider = %MusicSlider
@onready var sfx_slider: HSlider = %SfxSlider
@onready var follow_slider: HSlider = %FollowSlider
@onready var speed_slider: HSlider = %SpeedSlider
@onready var music_label: Label = %MusicLabel
@onready var sfx_label: Label = %SfxLabel
@onready var follow_label: Label = %FollowLabel
@onready var speed_label: Label = %SpeedLabel
@onready var panel: Control = $Panel

func _ready() -> void:
	visible = false
	mouse_filter = Control.MOUSE_FILTER_STOP
	process_mode = Node.PROCESS_MODE_ALWAYS
	# Show Control card (not only HudCanvas "PAUSED" text)
	if panel:
		panel.visible = true
	_apply_html_chrome()
	GameState.state_changed.connect(_on_state)

func _apply_html_chrome() -> void:
	## HTML .ps-card / pink border / pink resume — centered on full W×H
	var dim := get_node_or_null("Dim") as ColorRect
	var pc := panel as PanelContainer
	OverlayTheme.apply_pause_card(pc, dim)
	_center_panel(pc, 380.0, 420.0)
	# After reparent, resolve via panel (not "Panel/…" path from root)
	var vbox := pc.get_node_or_null("VBox") as VBoxContainer if pc else null
	var title := (vbox.get_node_or_null("Title") if vbox else null) as Label
	if title:
		title.text = "⏸ PAUSED"
		title.add_theme_color_override("font_color", Color.WHITE)
		title.add_theme_font_size_override("font_size", 32)
	OverlayTheme.style_label(music_label)
	OverlayTheme.style_label(sfx_label)
	OverlayTheme.style_label(follow_label)
	OverlayTheme.style_label(speed_label)
	OverlayTheme.style_slider(music_slider)
	OverlayTheme.style_slider(sfx_slider)
	OverlayTheme.style_slider(follow_slider)
	OverlayTheme.style_slider(speed_slider)
	var resume := (vbox.get_node_or_null("ResumeBtn") if vbox else null) as Button
	var display := (vbox.get_node_or_null("DisplayBtn") if vbox else null) as Button
	var keybinds := (vbox.get_node_or_null("KeybindsBtn") if vbox else null) as Button
	var menu := (vbox.get_node_or_null("MenuBtn") if vbox else null) as Button
	OverlayTheme.style_button(resume, "primary")
	if resume:
		resume.add_theme_font_size_override("font_size", 18)
		resume.custom_minimum_size.y = 48
	OverlayTheme.style_button(display, "ghost")
	OverlayTheme.style_button(keybinds, "ghost")
	OverlayTheme.style_button(menu, "ghost")
	# Section headers + hint (create if missing)
	if vbox and vbox.get_node_or_null("SecAudio") == null:
		var sa := Label.new()
		sa.name = "SecAudio"
		sa.text = "AUDIO"
		OverlayTheme.style_sec(sa)
		vbox.add_child(sa)
		vbox.move_child(sa, music_label.get_index() if music_label else 1)
		var sm := Label.new()
		sm.name = "SecMouse"
		sm.text = "MOUSE"
		OverlayTheme.style_sec(sm)
		vbox.add_child(sm)
		if follow_label:
			vbox.move_child(sm, follow_label.get_index())
		var hint := Label.new()
		hint.name = "Hint"
		hint.text = "tap outside or press P to resume · menu ends this run"
		hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		hint.add_theme_color_override("font_color", OverlayTheme.HINT)
		hint.add_theme_font_size_override("font_size", 11)
		vbox.add_child(hint)

func _center_panel(pc: PanelContainer, w: float, _h: float) -> void:
	if pc == null:
		return
	# HTML flex center — wrap panel in full-rect CenterContainer (anchors alone get thrash from playtest)
	var host: CenterContainer = get_node_or_null("CenterHost") as CenterContainer
	if host == null:
		host = CenterContainer.new()
		host.name = "CenterHost"
		host.set_anchors_preset(Control.PRESET_FULL_RECT)
		host.offset_left = 0
		host.offset_top = 0
		host.offset_right = 0
		host.offset_bottom = 0
		host.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(host)
		# Keep dim behind, card on top of host
		move_child(host, get_child_count() - 1)
	if pc.get_parent() != host:
		pc.reparent(host)
	pc.set_anchors_preset(Control.PRESET_TOP_LEFT)
	pc.anchor_right = 0.0
	pc.anchor_bottom = 0.0
	pc.offset_left = 0
	pc.offset_top = 0
	pc.offset_right = w
	pc.offset_bottom = 0
	pc.custom_minimum_size = Vector2(w, 0)
	pc.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	pc.size_flags_vertical = Control.SIZE_SHRINK_CENTER

func _on_state(_s: StringName) -> void:
	var paused := GameState.state == GameState.State.PAUSED
	visible = paused
	if paused:
		_center_panel(panel as PanelContainer, 380.0, 420.0)
		_sync_ui()

func _sync_ui() -> void:
	var st: Dictionary = ProgressStore.progress.get("settings", {}) if ProgressStore else {}
	if typeof(st) != TYPE_DICTIONARY:
		st = {}
	var music_v := float(st.get("music", AudioBus.music_volume * 100.0 if AudioBus else 100.0))
	var sfx_v := float(st.get("sfx", AudioBus.sfx_volume * 100.0 if AudioBus else 90.0))
	if music_slider:
		music_slider.value = music_v
	if sfx_slider:
		sfx_slider.value = sfx_v
	if music_label:
		music_label.text = "🎵 Music Volume  %d%%" % int(round(music_v))
	if sfx_label:
		sfx_label.text = "🔊 Sound FX  %d%%" % int(round(sfx_v))
	var follow := float(st.get("follow", Config.mouse_follow))
	if follow <= 1.0:
		follow *= 100.0
	var mspeed := float(st.get("mspeed", Config.mouse_speed))
	if mspeed <= 2.0:
		mspeed *= 100.0
	if follow_slider:
		follow_slider.value = clampf(follow, 35.0, 100.0)
	if speed_slider:
		speed_slider.value = clampf(mspeed, 70.0, 160.0)
	_refresh_mouse_labels()

func _refresh_mouse_labels() -> void:
	# HTML pause labels
	if follow_label and follow_slider:
		follow_label.text = "Cursor Follow Tightness  %d%%" % int(follow_slider.value)
	if speed_label and speed_slider:
		speed_label.text = "Movement Speed  %.2f×" % (speed_slider.value / 100.0)

func _save_setting(key: String, v) -> void:
	var st: Dictionary = ProgressStore.progress.get("settings", {}) if ProgressStore else {}
	if typeof(st) != TYPE_DICTIONARY:
		st = {}
	st[key] = v
	if ProgressStore:
		ProgressStore.progress["settings"] = st
		ProgressStore.queue_save()

func _on_music(v: float) -> void:
	if AudioBus:
		AudioBus.set_music_volume(v / 100.0)
	if music_label:
		music_label.text = "🎵 Music Volume  %d%%" % int(round(v))
	_save_setting("music", v)

func _on_sfx(v: float) -> void:
	if AudioBus:
		AudioBus.set_sfx_volume(v / 100.0)
	if sfx_label:
		sfx_label.text = "🔊 Sound FX  %d%%" % int(round(v))
	_save_setting("sfx", v)

func _on_follow(v: float) -> void:
	Config.mouse_follow = clampf(v / 100.0, 0.35, 1.0)
	_refresh_mouse_labels()
	_save_setting("follow", Config.mouse_follow)

func _on_speed(v: float) -> void:
	Config.mouse_speed = clampf(v / 100.0, 0.7, 1.6)
	_refresh_mouse_labels()
	_save_setting("mspeed", Config.mouse_speed)

func _unhandled_input(event: InputEvent) -> void:
	if GameState.state != GameState.State.PAUSED:
		return
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_M:
			_on_menu()
			get_viewport().set_input_as_handled()
		elif event.keycode == KEY_H:
			var help = get_tree().get_first_node_in_group("help_canvas")
			if help and help.has_method("open_help"):
				help.open_help()
			get_viewport().set_input_as_handled()
		elif event.is_action_pressed("pause") or event.keycode == KEY_ESCAPE or event.keycode == KEY_P:
			_on_resume()
			get_viewport().set_input_as_handled()

func _on_resume() -> void:
	GameState.set_state(GameState.State.PLAY)
	get_tree().paused = false
	if AudioBus:
		AudioBus.sfx("item")

func _on_menu() -> void:
	get_tree().paused = false
	GameState.return_to_title()
	if AudioBus:
		AudioBus.sfx("item")

func _on_display() -> void:
	var dm := get_tree().get_first_node_in_group("display_menu")
	if dm and dm.has_method("open_menu"):
		dm.open_menu()

func _on_keybinds() -> void:
	var kb := get_tree().get_first_node_in_group("keybinds_menu")
	if kb and kb.has_method("open_menu"):
		kb.open_menu()

func _on_settings() -> void:
	get_tree().paused = false
	GameState.set_state(GameState.State.SETTINGS)
