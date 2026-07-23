extends Control
## Settings panel — HTML #settings openSettings/syncSettingsUI 1:1 (audio, mouse, speedrun, links).

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
	GameState.state_changed.connect(func(_s):
		visible = GameState.state == GameState.State.SETTINGS
		if visible:
			_sync_ui()
	)

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
		speedrun_btn.text = "🏁 Speedrun Mode  %s" % ("ON" if on else "OFF")
		speedrun_btn.button_pressed = on

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
