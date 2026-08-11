extends SceneTree
## HTML meleeFx: f.t++ each frame; drop when t>=life. CombatHelpers.melee_fx must age.

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	await process_frame
	var ok := true
	var src := FileAccess.get_file_as_string("res://scripts/combat/CombatHelpers.gd")
	var i := src.find("func tick_fx")
	var chunk := src.substr(i, 1400) if i >= 0 else ""
	if chunk.find("melee_fx") < 0:
		print("[MFX] FAIL tick_fx must age melee_fx")
		ok = false
	else:
		print("[MFX] melee_fx in tick_fx ok")
	if chunk.find("f[\"t\"]") < 0 and chunk.find("f['t']") < 0:
		print("[MFX] FAIL must increment melee_fx t")
		ok = false
	else:
		print("[MFX] t increment ok")
	var ps := FileAccess.get_file_as_string("res://autoload/ProgressStore.gd")
	if ps.find("PROCESS_MODE_ALWAYS") < 0 or ps.find("tick_emblem_toasts") < 0:
		print("[MFX] FAIL ProgressStore should tick emblem toasts while paused")
		ok = false
	else:
		print("[MFX] emblem toast pause path ok")
	# Runtime: ring expires
	var CH: Node = root.get_node_or_null("/root/CombatHelpers")
	var GS: Node = root.get_node_or_null("/root/GameState")
	if CH and GS:
		CH.melee_fx = [{"ring": true, "t": 0.0, "life": 5.0, "x": 0.0, "y": 0.0}]
		GS.player_down = false
		GS.set_state(GS.State.PLAY)
		for _i in range(6):
			CH.tick_fx(1.0 / 60.0)
		if CH.melee_fx.size() != 0:
			print("[MFX] FAIL ring should expire after life frames size=", CH.melee_fx.size())
			ok = false
		else:
			print("[MFX] runtime expire ok")
	else:
		print("[MFX] runtime skip — structure only")
	if ok:
		print("[MFX] PASS")
		quit(0)
	else:
		print("[MFX] FAIL")
		quit(1)
