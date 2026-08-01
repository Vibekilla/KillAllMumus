extends SceneTree
## Boss HP/phases match HTML spawnBoss: round(base * (2.1 + stageIdx*0.07)), phases 3, twin 0.6.

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	await process_frame
	var src: String = FileAccess.get_file_as_string("res://scripts/enemies/bosses/BossController.gd")
	var ok: bool = true
	if src.find("2.1") < 0 or src.find("0.07") < 0:
		print("[BOSSHP] FAIL missing 2.1 + stageIdx*0.07 scale")
		ok = false
	if src.find("0.6") < 0:
		print("[BOSSHP] FAIL missing twin 0.6 pool")
		ok = false
	if src.find("intro_dlg") < 0 or src.find("_clear_wave_mobs") < 0:
		print("[BOSSHP] FAIL missing introDlg / clearWaveMobs")
		ok = false
	if src.find("phases = 3") < 0:
		print("[BOSSHP] FAIL phases should default to 3")
		ok = false
	# Formula vs stages.json (autoload may not bind as global in headless script)
	var raw_txt: String = FileAccess.get_file_as_string("res://data/stages.json")
	var parsed = JSON.parse_string(raw_txt)
	var list: Array = []
	if typeof(parsed) == TYPE_DICTIONARY and (parsed as Dictionary).has("stages"):
		list = (parsed as Dictionary)["stages"] as Array
	elif typeof(parsed) == TYPE_ARRAY:
		list = parsed as Array
	var expect_map: Dictionary = {
		0: 714.0, 1: 998.0, 2: 1254.0, 3: 1386.0, 4: 1476.0, 5: 1274.0, 6: 1663.0,
	}
	for i in range(mini(7, list.size())):
		var st_any = list[i]
		if typeof(st_any) != TYPE_DICTIONARY:
			continue
		var st: Dictionary = st_any as Dictionary
		var base: float = 0.0
		var port: String = "?"
		if st.has("boss") and typeof(st["boss"]) == TYPE_DICTIONARY:
			var bd: Dictionary = st["boss"] as Dictionary
			base = float(bd.get("hp", 0))
			port = str(bd.get("portrait", "?"))
		var html_hp: float = float(round(base * (2.1 + float(i) * 0.07)))
		var expv: float = float(expect_map.get(i, html_hp))
		print("[BOSSHP] stage", i, " ", port, " base=", base, " hp=", html_hp)
		if absf(html_hp - expv) > 1.0:
			print("[BOSSHP] FAIL stage", i, " expected", expv, " got", html_hp)
			ok = false
	if ok:
		print("[BOSSHP] PASS")
		quit(0)
	else:
		print("[BOSSHP] FAIL")
		quit(1)
