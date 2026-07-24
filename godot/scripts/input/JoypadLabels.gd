extends RefCounted
## Human-readable Xbox-style labels for JoyButton / JoyAxis (Steam + dual UI).

static func button_name(button: int) -> String:
	match button:
		JOY_BUTTON_A: return "A"
		JOY_BUTTON_B: return "B"
		JOY_BUTTON_X: return "X"
		JOY_BUTTON_Y: return "Y"
		JOY_BUTTON_BACK: return "View"
		JOY_BUTTON_GUIDE: return "Guide"
		JOY_BUTTON_START: return "Menu"
		JOY_BUTTON_LEFT_STICK: return "L3"
		JOY_BUTTON_RIGHT_STICK: return "R3"
		JOY_BUTTON_LEFT_SHOULDER: return "LB"
		JOY_BUTTON_RIGHT_SHOULDER: return "RB"
		JOY_BUTTON_DPAD_UP: return "D↑"
		JOY_BUTTON_DPAD_DOWN: return "D↓"
		JOY_BUTTON_DPAD_LEFT: return "D←"
		JOY_BUTTON_DPAD_RIGHT: return "D→"
		JOY_BUTTON_MISC1: return "Misc"
		JOY_BUTTON_PADDLE1: return "P1"
		JOY_BUTTON_PADDLE2: return "P2"
		JOY_BUTTON_PADDLE3: return "P3"
		JOY_BUTTON_PADDLE4: return "P4"
		JOY_BUTTON_TOUCHPAD: return "Pad"
		_: return "Btn%d" % button

static func axis_name(axis: int, axis_value: float) -> String:
	var side := "+" if axis_value >= 0.0 else "−"
	match axis:
		JOY_AXIS_LEFT_X: return "LS X%s" % side
		JOY_AXIS_LEFT_Y: return "LS Y%s" % side
		JOY_AXIS_RIGHT_X: return "RS X%s" % side
		JOY_AXIS_RIGHT_Y: return "RS Y%s" % side
		JOY_AXIS_TRIGGER_LEFT: return "LT"
		JOY_AXIS_TRIGGER_RIGHT: return "RT"
		_: return "Axis%d%s" % [axis, side]

static func event_label(e: InputEvent) -> String:
	if e is InputEventKey:
		var k := e as InputEventKey
		var code := k.physical_keycode if k.physical_keycode != 0 else k.keycode
		return OS.get_keycode_string(code)
	if e is InputEventJoypadButton:
		return button_name(int((e as InputEventJoypadButton).button_index))
	if e is InputEventJoypadMotion:
		var m := e as InputEventJoypadMotion
		return axis_name(int(m.axis), m.axis_value)
	return "?"
