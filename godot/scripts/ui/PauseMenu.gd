extends Control
## HTML #pausescreen — full pause card (audio, mouse, resume, display, controls, menu).

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
	GameState.state_changed.connect(_on_state)

func _on_state(_s: StringName) -> void:
	var paused := GameState.state == GameState.State.PAUSED
	visible = paused
	if paused:
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
		music_label.text = "🎵 Music  %d%%" % int(round(music_v))
	if sfx_label:
		sfx_label.text = "🔊 SFX  %d%%" % int(round(sfx_v))
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
	if follow_label and follow_slider:
		follow_label.text = "Follow  %d%%" % int(follow_slider.value)
	if speed_label and speed_slider:
		speed_label.text = "Speed  %.2f×" % (speed_slider.value / 100.0)

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
		music_label.text = "🎵 Music  %d%%" % int(round(v))
	_save_setting("music", v)

func _on_sfx(v: float) -> void:
	if AudioBus:
		AudioBus.set_sfx_volume(v / 100.0)
	if sfx_label:
		sfx_label.text = "🔊 SFX  %d%%" % int(round(v))
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
