extends RefCounted
## Steam / desktop controller defaults (Xbox layout). Adds joy events; keeps keyboard.
##
##   Left stick / D-pad  → move
##   A / RT              → shoot (hold)
##   LB / LT             → focus (hold; double-tap dash still works)
##   B                   → bomb
##   Y                   → melee (hold to charge)
##   X                   → special
##   RB                  → swap weapon
##   LS click            → switch melee
##   RS click            → cycle special
##   View/Back           → switch item
##   D-pad up            → use item (tap)
##   D-pad down          → interact (portal/shop)
##   Menu/Start          → pause
##   A / B (menus)       → accept / cancel

static func ensure_defaults() -> void:
	# Move: left stick only (D-pad reserved for items/interact so basic Xbox works)
	_ensure_axis("move_left", JOY_AXIS_LEFT_X, -1.0)
	_ensure_axis("move_right", JOY_AXIS_LEFT_X, 1.0)
	_ensure_axis("move_up", JOY_AXIS_LEFT_Y, -1.0)
	_ensure_axis("move_down", JOY_AXIS_LEFT_Y, 1.0)

	_ensure_button("shoot", JOY_BUTTON_A)
	_ensure_axis("shoot", JOY_AXIS_TRIGGER_RIGHT, 1.0)
	_ensure_button("focus", JOY_BUTTON_LEFT_SHOULDER)
	_ensure_axis("focus", JOY_AXIS_TRIGGER_LEFT, 1.0)
	_ensure_button("bomb", JOY_BUTTON_B)
	_ensure_button("melee", JOY_BUTTON_Y)
	_ensure_button("special", JOY_BUTTON_X)
	_ensure_button("swap", JOY_BUTTON_RIGHT_SHOULDER)
	_ensure_button("meleeswap", JOY_BUTTON_LEFT_STICK)
	_ensure_button("cycle_special", JOY_BUTTON_RIGHT_STICK)
	# D-pad: items + interact (stick for movement)
	_ensure_button("item_switch", JOY_BUTTON_DPAD_LEFT)
	_ensure_button("item_use", JOY_BUTTON_DPAD_RIGHT)
	_ensure_button("interact", JOY_BUTTON_DPAD_UP)
	_ensure_button("item_switch", JOY_BUTTON_BACK)  # also View/Select
	_ensure_button("pause", JOY_BUTTON_START)
	_ensure_button("ui_accept", JOY_BUTTON_A)
	_ensure_button("ui_cancel", JOY_BUTTON_B)

static func _ensure_button(action: String, button: int) -> void:
	if not InputMap.has_action(action):
		InputMap.add_action(action, 0.2)
	for e in InputMap.action_get_events(action):
		if e is InputEventJoypadButton and int((e as InputEventJoypadButton).button_index) == button:
			return
	var ev := InputEventJoypadButton.new()
	ev.button_index = button as JoyButton
	ev.pressed = true
	InputMap.action_add_event(action, ev)

static func _ensure_axis(action: String, axis: int, axis_value: float) -> void:
	if not InputMap.has_action(action):
		InputMap.add_action(action, 0.25)
	for e in InputMap.action_get_events(action):
		if e is InputEventJoypadMotion:
			var m := e as InputEventJoypadMotion
			if int(m.axis) == axis and signf(m.axis_value) == signf(axis_value):
				return
	var ev := InputEventJoypadMotion.new()
	ev.axis = axis as JoyAxis
	ev.axis_value = axis_value
	InputMap.action_add_event(action, ev)
