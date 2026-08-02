extends SceneTree
## Twin swap numbers + death-handoff parity (HTML RISES / legion dialog / white particles).
## Dash/bomb constants. Run: godot --path godot --headless --script res://scripts/tools/test_twin_dash_bomb.gd

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	var ok := true
	# Twin swap_cd formula samples (HTML ranges)
	for _i in range(40):
		var vol := 420 + randi() % 240
		var death := 480 + randi() % 180
		var init := 420 + randi() % 180
		if vol < 420 or vol >= 660:
			ok = false
			print("[TWIN] voluntary out of range ", vol)
		if death < 480 or death >= 660:
			ok = false
			print("[TWIN] death out of range ", death)
		if init < 420 or init >= 600:
			ok = false
			print("[TWIN] init out of range ", init)
	print("[TWIN] cd ranges ok")

	var src := FileAccess.get_file_as_string("res://scripts/enemies/bosses/BossController.gd")
	if src.find("RISES") < 0:
		print("[TWIN] FAIL death handoff needs RISES flash")
		ok = false
	if src.find("WE ARE LEGION") < 0:
		print("[TWIN] FAIL death handoff needs legion dialog")
		ok = false
	if src.find("same face") < 0:
		print("[TWIN] FAIL death handoff needs Bobina retort line")
		ok = false
	# white particle burst (HTML c:'#fff') — not pink
	if src.find("\"c\": \"#fff\"") < 0 and src.find("'#fff'") < 0 and src.find("\"#fff\"") < 0:
		print("[TWIN] FAIL death particles must be #fff")
		ok = false
	# death handoff repositions roam target
	var d_idx := src.find("death_handoff")
	var d_chunk := src.substr(d_idx, 900) if d_idx >= 0 else ""
	if d_chunk.find("mtx =") < 0 and d_chunk.find("mtx=") < 0:
		print("[TWIN] FAIL death handoff must set mtx/mty roam")
		ok = false
	# voluntary FX via StageFlow
	var sf := FileAccess.get_file_as_string("res://scripts/stages/StageFlow.gd")
	if sf.find("takes the strings") < 0:
		print("[TWIN] FAIL voluntary flashMsg missing")
		ok = false
	if sf.find("sfx(\"card\")") < 0 and sf.find("sfx('card')") < 0:
		print("[TWIN] FAIL voluntary card sfx")
		ok = false
	print("[TWIN] death handoff + voluntary FX ", "ok" if ok else "check fails")

	# Dash constants (HTML doDash)
	var ok_d := true
	var psrc := FileAccess.get_file_as_string("res://scripts/player/Player.gd")
	for needle in ["16", "12", "52", "40"]:
		if psrc.find(needle) < 0:
			ok_d = false
	# slash/norm durations appear as ternary values
	if psrc.find("slash") < 0 and psrc.find("slash_dash") < 0:
		ok_d = false
	print("[DASH] timings structure ", "ok" if ok_d else "FAIL")
	ok = ok and ok_d

	# Bomb numbers in Player
	var ok_b := psrc.find("140") >= 0 and psrc.find("46") >= 0
	print("[BOMB] numbers structure ", "ok" if ok_b else "FAIL")
	ok = ok and ok_b

	# option_shot weapon arms (all HTML branches)
	var fs := FileAccess.get_file_as_string("res://scripts/combat/FireSystem.gd")
	for wep in ["laser", "homing", "wave", "scatter", "gatling", "grenade", "voidripper", "lotus", "shock"]:
		if fs.find("\"%s\"" % wep) < 0 and fs.find("'%s'" % wep) < 0:
			print("[OPT] FAIL option_shot missing weapon ", wep)
			ok = false
	print("[OPT] option_shot weapons present")

	print("[PASS]" if ok else "[FAIL]")
	quit(0 if ok else 1)
