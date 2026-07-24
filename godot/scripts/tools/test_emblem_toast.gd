extends SceneTree
## Emblem toast timer lives in ProgressStore (HTML e.t++ / dur 210).
## Run: godot --path godot --headless --script res://scripts/tools/test_emblem_toast.gd

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	var ok := true
	var src := FileAccess.get_file_as_string("res://autoload/ProgressStore.gd")
	if "tick_emblem_toasts" not in src:
		print("[FAIL] missing tick_emblem_toasts")
		ok = false
	else:
		print("[TOAST] tick_emblem_toasts ok")
	if "sfx(\"extend\")" not in src and "sfx('extend')" not in src:
		print("[FAIL] unlock should sfx extend")
		ok = false
	else:
		print("[TOAST] unlock sfx ok")
	var hud := FileAccess.get_file_as_string("res://scripts/ui/menu/draw_hud.gd")
	if 'e["t"] = int(e.get("t", 0)) + 1' in hud or "e[\"t\"] = int" in hud:
		print("[FAIL] draw must not advance toast timer")
		ok = false
	else:
		print("[TOAST] draw presentation-only ok")
	if "EMBLEM UNLOCKED" not in hud:
		print("[FAIL] missing banner text")
		ok = false
	else:
		print("[TOAST] banner text ok")
	var gs := FileAccess.get_file_as_string("res://autoload/GameState.gd")
	if "tick_emblem_toasts" not in gs:
		print("[FAIL] GameState should tick toasts on sim")
		ok = false
	else:
		print("[TOAST] GameState sim tick ok")
	print("[PASS]" if ok else "[FAIL]")
	quit(0 if ok else 1)
