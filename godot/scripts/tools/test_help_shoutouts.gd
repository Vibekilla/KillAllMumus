extends SceneTree
## Help copy + shoutouts list parity smoke.
## Run: godot --path godot --headless --script res://scripts/tools/test_help_shoutouts.gd

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	var ok := true
	var help := FileAccess.get_file_as_string("res://scripts/ui/menu/HelpData.gd")
	if "hold Use (0.8s)" in help:
		print("[FAIL] help still says hold 0.8s for consumables")
		ok = false
	else:
		print("[HELP] tap consumables copy ok")
	if "Controller" not in help:
		print("[FAIL] missing controller help row")
		ok = false
	else:
		print("[HELP] controller row ok")
	var title := FileAccess.get_file_as_string("res://scripts/ui/TitleScreen.gd")
	for url in [
		"bobina.moe", "itsvibekilla", "bobina_council", "picklecharts.com", "krakenfx",
	]:
		if url not in title:
			print("[FAIL] missing shoutout ", url)
			ok = false
	if ok:
		print("[SHOUT] urls ok")
	if "list_bottom" not in title and "row_h" not in title:
		print("[FAIL] shoutouts layout not sized for full list")
		ok = false
	else:
		print("[SHOUT] layout fit ok")
	var shot := FileAccess.get_file_as_string("res://scripts/tools/screenshot_playtest.gd")
	if "godot_menu_help" not in shot or "godot_menu_shoutouts" not in shot:
		print("[FAIL] dual stills missing")
		ok = false
	else:
		print("[DUAL] help/shoutouts shots ok")
	print("[PASS]" if ok else "[FAIL]")
	quit(0 if ok else 1)
