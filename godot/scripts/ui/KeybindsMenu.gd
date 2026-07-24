extends Control
## HTML #keybinds — rebind game actions (keyboard + gamepad).

const GamepadMap = preload("res://scripts/input/GamepadMap.gd")
const JoypadLabels = preload("res://scripts/input/JoypadLabels.gd")

const ACTIONS := [
	{"action": "shoot", "label": "Fire"},
	{"action": "focus", "label": "Focus / dash"},
	{"action": "melee", "label": "Melee"},
	{"action": "meleeswap", "label": "Switch melee"},
	{"action": "bomb", "label": "Bomb"},
	{"action": "swap", "label": "Swap weapon"},
	{"action": "special", "label": "Special"},
	{"action": "cycle_special", "label": "Cycle special"},
	{"action": "pause", "label": "Pause"},
	{"action": "interact", "label": "Interact"},
	{"action": "item_switch", "label": "Item switch"},
	{"action": "item_use", "label": "Use item (tap)"},
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

@onready var list: VBoxContainer = %List
var _waiting_action: String = ""
var _row_btns: Dictionary = {}  # action -> Button

func _ready() -> void:
	visible = false
	process_mode = Node.PROCESS_MODE_ALWAYS
	add_to_group("keybinds_menu")
	_build_list()

func open_menu() -> void:
	visible = true
	_waiting_action = ""
	_refresh_labels()

func close_menu() -> void:
	visible = false
	_waiting_action = ""

func _build_list() -> void:
	if list == null:
		return
	for c in list.get_children():
		c.queue_free()
	_row_btns.clear()
	for a in ACTIONS:
		var row := HBoxContainer.new()
		row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var lab := Label.new()
		lab.text = str(a["label"])
		lab.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		lab.custom_minimum_size = Vector2(160, 0)
		var btn := Button.new()
		btn.custom_minimum_size = Vector2(100, 28)
		btn.text = _key_name(str(a["action"]))
		var act := str(a["action"])
		btn.pressed.connect(func(): _start_rebind(act))
		row.add_child(lab)
		row.add_child(btn)
		list.add_child(row)
		_row_btns[act] = btn

func _key_name(action: String) -> String:
	## "Z · A" style — keyboard primary, first gamepad glyph secondary
	if not InputMap.has_action(action):
		return "?"
	var key_s := ""
	var joy_s := ""
	for e in InputMap.action_get_events(action):
		if e is InputEventKey and key_s == "":
			key_s = JoypadLabels.event_label(e)
		elif (e is InputEventJoypadButton or e is InputEventJoypadMotion) and joy_s == "":
			joy_s = JoypadLabels.event_label(e)
	if key_s != "" and joy_s != "":
		return "%s · %s" % [key_s, joy_s]
	if key_s != "":
		return key_s
	if joy_s != "":
		return joy_s
	return "—"

func _start_rebind(action: String) -> void:
	_waiting_action = action
	if _row_btns.has(action):
		_row_btns[action].text = "press key/pad…"
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
		_row_btns[act].text = _key_name(str(act))

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
