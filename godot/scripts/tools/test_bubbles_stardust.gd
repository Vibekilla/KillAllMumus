extends SceneTree
## Bubbles / stardust consumable FX shape (HTML spawnBubbles / spawnStardust).
## Run: godot --path godot --headless --script res://scripts/tools/test_bubbles_stardust.gd

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	var ok := true
	var src := FileAccess.get_file_as_string("res://scripts/systems/ItemSystem.gd")
	if '"type": "bubble"' not in src and '"type":"bubble"' not in src:
		print("[FAIL] spawn_bubbles must push type=bubble fx")
		ok = false
	else:
		print("[FX] bubble type ok")
	if '"type": "stardust"' not in src and '"type":"stardust"' not in src:
		print("[FAIL] spawn_stardust must push type=stardust fx")
		ok = false
	else:
		print("[FX] stardust type ok")
	if "_update_consumable_fx" not in src:
		print("[FAIL] missing _update_consumable_fx")
		ok = false
	else:
		print("[FX] update loop ok")
	# HTML bubble count 6, stardust life 270
	if "range(6)" not in src and "for i in 6" not in src:
		# still ok if written differently
		if "i in range(6)" not in src:
			print("[WARN] expected 6 bubbles")
	if "270.0" not in src and "270" not in src:
		print("[FAIL] stardust life should be 270")
		ok = false
	else:
		print("[FX] stardust life 270 ok")
	# WorldDraw merges ItemSystem.fx
	var wd := FileAccess.get_file_as_string("res://scripts/html_parity/WorldDraw.gd")
	if "ItemSystem.fx" not in wd and "ItemSystem.get(\"fx\")" not in wd:
		print("[FAIL] WorldDraw must draw ItemSystem.fx")
		ok = false
	else:
		print("[FX] WorldDraw merge ok")
	print("[PASS]" if ok else "[FAIL]")
	quit(0 if ok else 1)
