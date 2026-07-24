extends SceneTree
## Consumables are tap-to-use (no 0.8s hold). Cooldown remains 180 frames.
## Run: godot --path godot --headless --script res://scripts/tools/test_consumable_tap.gd

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	var ok := true
	var cs = load("res://scripts/systems/ConsumableSystem.gd")
	if cs == null:
		print("[FAIL] cannot load ConsumableSystem")
		quit(1)
		return
	var node: Node = cs.new()
	# No HOLD_FRAMES constant — tap only
	var has_hold := "HOLD_FRAMES" in node
	if has_hold:
		print("[FAIL] HOLD_FRAMES still present")
		ok = false
	else:
		print("[TAP] HOLD_FRAMES removed ok")
	# Cooldown still 3s
	var cd := float(node.get("COOLDOWN_FRAMES"))
	if absf(cd - 180.0) > 0.01:
		print("[FAIL] COOLDOWN_FRAMES expected 180 got ", cd)
		ok = false
	else:
		print("[TAP] COOLDOWN_FRAMES=180 ok")
	# Source contract: tick uses just_pressed
	var src := FileAccess.get_file_as_string("res://scripts/systems/ConsumableSystem.gd")
	if "is_action_just_pressed(\"item_use\")" not in src:
		print("[FAIL] tick must use is_action_just_pressed item_use")
		ok = false
	else:
		print("[TAP] just_pressed item_use ok")
	if "HOLD_FRAMES" in src:
		print("[FAIL] HOLD_FRAMES still in source")
		ok = false
	node.free()
	print("[PASS]" if ok else "[FAIL]")
	quit(0 if ok else 1)
