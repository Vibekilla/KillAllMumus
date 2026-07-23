extends Control
## Settings panel — HTML #settings openSettings/syncSettingsUI 1:1 (audio, mouse, speedrun, links).

const OverlayTheme = preload("res://scripts/ui/menu/OverlayTheme.gd")

@onready var music_slider: HSlider = %MusicSlider
@onready var sfx_slider: HSlider = %SfxSlider
@onready var music_label: Label = %MusicLabel
@onready var sfx_label: Label = %SfxLabel
@onready var follow_slider: HSlider = %FollowSlider
@onready var speed_slider: HSlider = %SpeedSlider
@onready var follow_label: Label = %FollowLabel
@onready var speed_label: Label = %SpeedLabel
@onready var speedrun_btn: Button = %SpeedrunBtn
@onready var reset_confirm: Control = %ResetConfirm

func _ready() -> void:
	visible = false
	process_mode = Node.PROCESS_MODE_ALWAYS
	if reset_confirm:
		reset_confirm.visible = false
	_apply_html_chrome()
	GameState.state_changed.connect(func(_s):
		visible = GameState.state == GameState.State.SETTINGS
		if visible:
			_sync_ui()
	)

func _apply_html_chrome() -> void:
	## HTML .set-card — violet border; mouse controls live in Controls modal (not main settings)
	var dim := get_node_or_null("Dim") as ColorRect
	var panel := get_node_or_null("Panel") as PanelContainer
	OverlayTheme.apply_settings_card(panel, dim)
	if panel:
		var w := 420.0
		var host: CenterContainer = get_node_or_null("CenterHost") as CenterContainer
		if host == null:
			host = CenterContainer.new()
			host.name = "CenterHost"
			host.set_anchors_preset(Control.PRESET_FULL_RECT)
			host.mouse_filter = Control.MOUSE_FILTER_IGNORE
			add_child(host)
			move_child(host, get_child_count() - 1)
		if panel.get_parent() != host:
			panel.reparent(host)
		panel.set_anchors_preset(Control.PRESET_TOP_LEFT)
		panel.custom_minimum_size = Vector2(w, 0)
		panel.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		panel.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	var title := get_node_or_null("Panel/VBox/Title") as Label
	if title:
		title.add_theme_color_override("font_color", OverlayTheme.TITLE_SET)
		title.add_theme_font_size_override("font_size", 22)
	var sub := get_node_or_null("Panel/VBox/Sub") as Label
	if sub:
		sub.add_theme_color_override("font_color", OverlayTheme.SUB)
		sub.add_theme_font_size_override("font_size", 12)
	var vbox: Node = null
	if panel:
		vbox = panel.get_node_or_null("VBox")
	for sec_name in ["SecAudio", "SecGame", "SecMouse", "SecMore"]:
		var sec := (vbox.get_node_or_null(sec_name) if vbox else null) as Label
		if sec:
			OverlayTheme.style_sec(sec)
			sec.text = sec.text.to_upper()
	# HTML main settings has NO mouse sliders (those are under Controls / pause)
	for n in ["SecMouse", "FollowLabel", "FollowSlider", "SpeedLabel", "SpeedSlider"]:
		var node: Node = null
		if n == "FollowLabel":
			node = follow_label
		elif n == "FollowSlider":
			node = follow_slider
		elif n == "SpeedLabel":
			node = speed_label
		elif n == "SpeedSlider":
			node = speed_slider
		elif vbox:
			node = vbox.get_node_or_null(n)
		if node and node is CanvasItem:
			(node as CanvasItem).visible = false
	OverlayTheme.style_label(music_label)
	OverlayTheme.style_label(sfx_label)
	OverlayTheme.style_slider(music_slider)
	OverlayTheme.style_slider(sfx_slider)
	OverlayTheme.style_button(speedrun_btn, "ghost")
	if speedrun_btn:
		speedrun_btn.text = "Skip villain monologues"
	# HTML .set-hint copy under rows
	if vbox and vbox.get_node_or_null("HintMusic") == null:
		_insert_hint(vbox, music_slider, "HintMusic", "Bobina's lofi radio stream.")
		_insert_hint(vbox, sfx_slider, "HintSfx", "Shots, hits, pickups and jingles.")
		if speedrun_btn:
			_insert_hint(vbox, speedrun_btn, "HintSpeedrun", "“Bobina hates monologues too.” Cuts straight to the fights.")
		var reset_n := vbox.get_node_or_null("ResetInvBtn")
		if reset_n:
			_insert_hint(vbox, reset_n, "HintReset", "Clears bought gear & skulls. Keeps emblems, outfits & NG+.")
	# HTML section labels: Display / Controls / Data (not single “MORE”)
	var sec_more := vbox.get_node_or_null("SecMore") as Label if vbox else null
	if sec_more:
		sec_more.text = "DISPLAY"
	var display := (vbox.get_node_or_null("DisplayBtn") if vbox else null) as Button
	var keybinds := (vbox.get_node_or_null("KeybindsBtn") if vbox else null) as Button
	var help := (vbox.get_node_or_null("HelpBtn") if vbox else null) as Button
	var reset_btn := (vbox.get_node_or_null("ResetInvBtn") if vbox else null) as Button
	var close := (vbox.get_node_or_null("CloseBtn") if vbox else null) as Button
	if vbox and vbox.get_node_or_null("SecControls") == null and keybinds:
		var sc := Label.new()
		sc.name = "SecControls"
		sc.text = "CONTROLS"
		OverlayTheme.style_sec(sc)
		vbox.add_child(sc)
		vbox.move_child(sc, keybinds.get_index())
		var sd := Label.new()
		sd.name = "SecData"
		sd.text = "DATA"
		OverlayTheme.style_sec(sd)
		vbox.add_child(sd)
		if reset_btn:
			vbox.move_child(sd, reset_btn.get_index())
	# Speedrun row label like HTML “🏁 Speedrun Mode … OFF”
	if vbox and vbox.get_node_or_null("SpeedrunLabel") == null and speedrun_btn:
		var sl := Label.new()
		sl.name = "SpeedrunLabel"
		sl.text = "🏁 Speedrun Mode"
		OverlayTheme.style_label(sl)
		vbox.add_child(sl)
		vbox.move_child(sl, speedrun_btn.get_index())
	OverlayTheme.style_button(display, "ghost")
	OverlayTheme.style_button(keybinds, "ghost")
	OverlayTheme.style_button(help, "help")
	OverlayTheme.style_button(reset_btn, "ghost")
	OverlayTheme.style_button(close, "ghost")
	var ver := (vbox.get_node_or_null("Ver") if vbox else null) as Label
	if ver:
		ver.add_theme_color_override("font_color", Color(0.416, 0.353, 0.447))
		ver.add_theme_font_size_override("font_size", 10)
		ver.text = "🐻 Bobina: KILL ALL MUMUS!!  ·  v1.9.0  ·  A Bobina Council production"
	if reset_confirm is PanelContainer:
		(reset_confirm as PanelContainer).add_theme_stylebox_override("panel", OverlayTheme.card_style(OverlayTheme.PINK, 16))

func _insert_hint(vbox: VBoxContainer, after: Node, name: String, text: String) -> void:
	if after == null or vbox == null:
		return
	var h := Label.new()
	h.name = name
	h.text = text
	h.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	h.add_theme_color_override("font_color", Color(0.55, 0.48, 0.60))
	h.add_theme_font_size_override("font_size", 11)
	vbox.add_child(h)
	vbox.move_child(h, after.get_index() + 1)

func _sync_ui() -> void:
	## HTML syncSettingsUI
	var st: Dictionary = ProgressStore.progress.get("settings", {}) if ProgressStore else {}
	if typeof(st) != TYPE_DICTIONARY:
		st = {}
	var music_v := float(st.get("music", AudioBus.music_volume * 100.0)) if AudioBus else 100.0
	var sfx_v := float(st.get("sfx", AudioBus.sfx_volume * 100.0)) if AudioBus else 90.0
	if music_slider:
		music_slider.value = music_v
	if sfx_slider:
		sfx_slider.value = sfx_v
	_set_pct_label(music_label, "🎵 Music Volume", music_v)
	_set_pct_label(sfx_label, "🔊 Sound FX", sfx_v)
	var follow := float(st.get("follow", Config.mouse_follow * 100.0))
	# HTML stores follow 0–1 as bobina_follow; UI is 35–100%
	if follow <= 1.0:
		follow = follow * 100.0
	var mspeed := float(st.get("mspeed", Config.mouse_speed * 100.0))
	if mspeed <= 2.0:
		mspeed = mspeed * 100.0
	if follow_slider:
		follow_slider.value = clampf(follow, 35.0, 100.0)
	if speed_slider:
		speed_slider.value = clampf(mspeed, 70.0, 160.0)
	_refresh_follow_labels()
	_refresh_speedrun()

func _set_pct_label(lab: Label, prefix: String, v: float) -> void:
	if lab:
		lab.text = "%s  %d%%" % [prefix, int(round(v))]

func _refresh_follow_labels() -> void:
	if follow_label and follow_slider:
		follow_label.text = "Cursor Follow Tightness  %d%%" % int(follow_slider.value)
	if speed_label and speed_slider:
		speed_label.text = "Movement Speed  %.2f×" % (speed_slider.value / 100.0)

func _refresh_speedrun() -> void:
	if speedrun_btn:
		var on := GameState.speedrun
		# HTML: button is "Skip villain monologues"; status on the row label
		speedrun_btn.text = "Skip villain monologues"
		speedrun_btn.button_pressed = on
		if on:
			speedrun_btn.add_theme_color_override("font_color", Color(0.776, 0.949, 0.682))
		else:
			speedrun_btn.add_theme_color_override("font_color", OverlayTheme.MUTED_BTN)
	var vbox := get_node_or_null("CenterHost/Panel/VBox")
	if vbox == null:
		var p := get_node_or_null("Panel")
		if p:
			vbox = p.get_node_or_null("VBox")
	var sl := vbox.get_node_or_null("SpeedrunLabel") as Label if vbox else null
	if sl:
		var on2 := GameState.speedrun
		sl.text = "🏁 Speedrun Mode                    %s" % ("ON" if on2 else "OFF")
		sl.add_theme_color_override("font_color", Color(1.0, 0.82, 0.48) if on2 else OverlayTheme.LABEL)

func _on_music(v: float) -> void:
	if AudioBus:
		AudioBus.set_music_volume(v / 100.0)
	_set_pct_label(music_label, "🎵 Music Volume", v)
	_save_setting("music", v)

func _on_sfx(v: float) -> void:
	if AudioBus:
		AudioBus.set_sfx_volume(v / 100.0)
	_set_pct_label(sfx_label, "🔊 Sound FX", v)
	_save_setting("sfx", v)

func _on_follow(v: float) -> void:
	Config.mouse_follow = clampf(v / 100.0, 0.35, 1.0)
	_refresh_follow_labels()
	_save_setting("follow", Config.mouse_follow)

func _on_speed(v: float) -> void:
	Config.mouse_speed = clampf(v / 100.0, 0.7, 1.6)
	_refresh_follow_labels()
	_save_setting("mspeed", Config.mouse_speed)

func _on_speedrun() -> void:
	GameState.speedrun = not GameState.speedrun
	_save_setting("speedrun", 1.0 if GameState.speedrun else 0.0)
	_refresh_speedrun()
	if AudioBus:
		AudioBus.sfx("item")

func _save_setting(key: String, v) -> void:
	var st: Dictionary = ProgressStore.progress.get("settings", {}) if ProgressStore else {}
	if typeof(st) != TYPE_DICTIONARY:
		st = {}
	st[key] = v
	if ProgressStore:
		ProgressStore.progress["settings"] = st
		ProgressStore.queue_save()

func _on_display() -> void:
	var dm := get_tree().get_first_node_in_group("display_menu")
	if dm and dm.has_method("open_menu"):
		dm.open_menu()

func _on_keybinds() -> void:
	var kb := get_tree().get_first_node_in_group("keybinds_menu")
	if kb and kb.has_method("open_menu"):
		kb.open_menu()

func _on_help() -> void:
	var help = get_tree().get_first_node_in_group("help_canvas")
	if help and help.has_method("open_help"):
		help.open_help()

func _on_reset_inventory() -> void:
	## HTML opens confirm modal first
	if reset_confirm:
		reset_confirm.visible = true
	else:
		_confirm_reset()

func _on_reset_cancel() -> void:
	if reset_confirm:
		reset_confirm.visible = false

func _confirm_reset() -> void:
	if reset_confirm:
		reset_confirm.visible = false
	if ProgressStore:
		ProgressStore.reset_inventory()
	if CombatHelpers:
		CombatHelpers.flash("🗑 Inventory reset — starter kit restored", 120.0)
	if AudioBus:
		AudioBus.sfx("item")

func _on_close() -> void:
	if reset_confirm:
		reset_confirm.visible = false
	GameState.return_to_title()

func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		return
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_R:
		_on_reset_inventory()
		get_viewport().set_input_as_handled()
		return
	if event.is_action_pressed("shoot") or (event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE):
		if reset_confirm and reset_confirm.visible:
			_on_reset_cancel()
		else:
			_on_close()
		get_viewport().set_input_as_handled()
