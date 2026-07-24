extends SceneTree
## GamepadMap adds joy events; keyboard remains.
## Run: godot --path godot --headless --script res://scripts/tools/test_gamepad_map.gd

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	var ok := true
	var GP = load("res://scripts/input/GamepadMap.gd")
	if GP == null:
		print("[FAIL] load GamepadMap")
		quit(1)
		return
	GP.ensure_defaults()
	for action in ["shoot", "focus", "bomb", "melee", "special", "swap", "pause", "move_left"]:
		if not InputMap.has_action(action):
			print("[FAIL] missing action ", action)
			ok = false
			continue
		var has_key := false
		var has_joy := false
		for e in InputMap.action_get_events(action):
			if e is InputEventKey:
				has_key = true
			if e is InputEventJoypadButton or e is InputEventJoypadMotion:
				has_joy = true
		if not has_joy:
			print("[FAIL] no joy bind on ", action)
			ok = false
		else:
			print("[PAD] ", action, " joy ok key=", has_key)
	var ir := FileAccess.get_file_as_string("res://scripts/input/InputRouter.gd")
	if "GamepadMap" not in ir or "InputEventJoypadButton" not in ir:
		print("[FAIL] InputRouter not wired for gamepad")
		ok = false
	else:
		print("[PAD] InputRouter joy routing ok")
	print("[PASS]" if ok else "[FAIL]")
	quit(0 if ok else 1)
