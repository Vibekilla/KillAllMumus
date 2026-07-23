extends Control
## Settings panel — HTML openSettings/syncSettingsUI parity (volume + display).

@onready var music_slider: HSlider = %MusicSlider
@onready var sfx_slider: HSlider = %SfxSlider

func _ready() -> void:
	visible = false
	process_mode = Node.PROCESS_MODE_ALWAYS
	GameState.state_changed.connect(func(s):
		visible = (s == &"SETTINGS")
		if visible:
			_sync_ui()
	)

func _sync_ui() -> void:
	## HTML syncSettingsUI
	var st: Dictionary = ProgressStore.progress.get("settings", {})
	if music_slider:
		music_slider.value = float(st.get("music", AudioBus.music_volume * 100.0))
	if sfx_slider:
		sfx_slider.value = float(st.get("sfx", AudioBus.sfx_volume * 100.0))

func _on_music(v: float) -> void:
	AudioBus.set_music_volume(v / 100.0)
	_save_setting("music", v)

func _on_sfx(v: float) -> void:
	AudioBus.set_sfx_volume(v / 100.0)
	_save_setting("sfx", v)

func _save_setting(key: String, v: float) -> void:
	var st: Dictionary = ProgressStore.progress.get("settings", {})
	if typeof(st) != TYPE_DICTIONARY:
		st = {}
	st[key] = v
	ProgressStore.progress["settings"] = st
	ProgressStore.queue_save()

func _on_display() -> void:
	var dm := get_tree().get_first_node_in_group("display_menu")
	if dm and dm.has_method("open_menu"):
		dm.open_menu()

func _on_help() -> void:
	## HTML set-help → openHelp
	var help = get_tree().get_first_node_in_group("help_canvas")
	if help and help.has_method("open_help"):
		help.open_help()

func _on_reset_inventory() -> void:
	## HTML ri-confirm → resetInventory
	ProgressStore.reset_inventory()
	CombatHelpers.flash("🗑 Inventory reset — starter kit restored", 120.0)
	if AudioBus:
		AudioBus.sfx("item")

func _on_close() -> void:
	GameState.return_to_title()

func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		return
	# R key = reset inventory (HTML confirm path simplified for parity API)
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_R:
		_on_reset_inventory()
		get_viewport().set_input_as_handled()
		return
	if event.is_action_pressed("shoot") or (event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE):
		_on_close()
		get_viewport().set_input_as_handled()
