extends SceneTree
## JoypadLabels stay. The Controls buttons show HTML keyName only (no joy suffix).
## Run: godot --path godot --headless --script res://scripts/tools/test_joypad_labels.gd

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	var ok := true
	var JL = load("res://scripts/input/JoypadLabels.gd")
	if JL == null:
		print("[FAIL] load JoypadLabels")
		quit(1)
		return
	if JL.button_name(JOY_BUTTON_A) != "A":
		print("[FAIL] A label")
		ok = false
	else:
		print("[PAD] A ok")
	if JL.button_name(JOY_BUTTON_LEFT_SHOULDER) != "LB":
		print("[FAIL] LB label")
		ok = false
	else:
		print("[PAD] LB ok")
	if "RT" not in JL.axis_name(JOY_AXIS_TRIGGER_RIGHT, 1.0):
		print("[FAIL] RT axis")
		ok = false
	else:
		print("[PAD] RT ok")
	var kb := FileAccess.get_file_as_string("res://scripts/ui/KeybindsMenu.gd")
	if "JoypadLabels" not in kb or "_apply_joy_bind" not in kb:
		print("[FAIL] KeybindsMenu missing joy rebind")
		ok = false
	else:
		print("[PAD] keybinds joy rebind ok")
	if "%s · %s" in kb or "press key/pad" in kb:
		print("[FAIL] keybind button still appends a joy glyph or the old waiting text")
		ok = false
	elif "press…" not in kb:
		print("[FAIL] waiting text should be press…")
		ok = false
	else:
		print("[PAD] keyboard-only label ok")
	for frag in ["Melee (hold=charge)", "Interact / Shop", "Use Item (tap)", "Focus / Dash"]:
		if frag not in kb:
			print("[FAIL] BIND_LIST label missing: ", frag)
			ok = false
	if ok:
		print("[PAD] bind labels ok")
	print("[PASS]" if ok else "[FAIL]")
	quit(0 if ok else 1)
